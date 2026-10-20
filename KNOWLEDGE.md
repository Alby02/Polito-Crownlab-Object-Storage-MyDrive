# Project Knowledge

Technical reference for the CrownLabs personal-storage research project.

The analysis refers to [CrownLabs commit `ce16db0be390f1245f8e0db599310c43a8c6bf1d`](https://github.com/netgroup-polito/CrownLabs/commit/ce16db0be390f1245f8e0db599310c43a8c6bf1d), inspected on 20 October 2026.

## 1. Current CrownLabs implementation

### 1.1 Main concepts

| Concept | Role |
| --- | --- |
| **Tenant** | A CrownLabs user with a personal namespace and access to workspaces |
| **Workspace** | A collection of templates and their access permissions, such as Utilities or a course |
| **Template** | Defines an environment's image, resources, and optional My Drive attachment |
| **Instance** | A user's launched environment and the resources CrownLabs creates for it |
| **VM / VMI** | KubeVirt resources for persistent and running virtual-machine environments |
| **PVC / PV** | Kubernetes objects that request and describe access to persistent storage |
| **StorageClass** | Selects how a PVC is provisioned |
| **My Drive** | A user's persistent filesystem, independent of any individual VM |
| **SharedVolume** | Storage shared within an authorized workspace |

A PV represents access to backend storage. Different PVs can therefore refer to the same storage allocation without duplicating its data.

### 1.2 Storage architecture and VM attachment

CrownLabs personal storage uses Rook-managed Ceph, CephFS, and NFS-Ganesha. KubeVirt exposes the mounted filesystem to a VM through VirtioFS.

```text
Ceph → CephFS → NFS-Ganesha → Kubernetes node/pod → VirtioFS → VM guest
                                                                    /media/mydrive
```

The data path has five layers:

1. CephFS stores the files.
2. NFS-Ganesha exports the filesystem over the network.
3. Kubernetes mounts the storage in the KubeVirt `virt-launcher` pod.
4. KubeVirt exposes it to the guest as a VirtioFS filesystem device.
5. Cloud-init mounts that device at `/media/mydrive` inside the VM.

The node-side protocol is NFS, while the guest sees VirtioFS. My Drive is attached as a shared filesystem and is separate from the VM's root disk.

Sources: [storage infrastructure][storage-doc], [NFS StorageClass][nfs-sc], [VM filesystem construction][vm-forge], and [cloud-init mounts][cloudinit].

### 1.3 Namespace organization

Workspace definitions and user workloads live in separate namespaces:

- `workspace-<workspace-name>` contains templates and workspace resources.
- `tenant-<tenant-name>` contains the user's Instances, pods, VMs, and My Drive mirror PVC.
- `mydrive-pvcs` contains the original My Drive PVCs; this namespace is configurable.

For example, Tenant `s360540` uses namespace `tenant-s360540`, original PVC `s360540-drive`, and mirror PVC `s360540-drive-mirror`. Dots in Tenant names are replaced with hyphens, and long generated names may be truncated.

An Instance runs in the Tenant namespace but references a Template in a workspace namespace. This applies both to course VMs and to the Utilities file-manager Template.

Sources: [namespace naming][namespace-forge], [frontend instance creation][frontend-create], and [My Drive launcher][frontend-mydrive].

### 1.4 Resource topology

This example uses Tenant `s360540`; the course workspace ID is illustrative.

```text
workspace-utilities
  └─ File-manager Template

workspace-<course ID>
  └─ Course VM Templates

tenant-s360540
  ├─ File-manager Instance and pod
  ├─ Course VM Instances and virt-launcher pods
  └─ s360540-drive-mirror PVC → mirror PV ─┐
                                           ├─ same backing storage
mydrive-pvcs                               │
  └─ s360540-drive PVC → original PV ──────┘
```

PVs are cluster-scoped; their position above only shows which PVC binds to them. The file manager is an interface to the same persistent files used by the VMs, while the NFS server is a separate infrastructure component.

### 1.5 Kubernetes namespace and binding constraints

Two Kubernetes constraints motivate CrownLabs' mirroring mechanism:

1. A pod can reference only a PVC in its own namespace.
2. A PV binds to one PVC; `ReadWriteMany` does not allow several PVCs to bind to the same PV object.

`ReadWriteMany` allows multiple nodes or pods to mount compatible shared storage, but it does not remove namespace or binding restrictions. A VM in `tenant-s360540` therefore cannot directly reference `mydrive-pvcs/s360540-drive`, and an ordinary new PVC would usually provision separate storage.

These restrictions concern Kubernetes objects. Access to the underlying NFS export is governed separately by networking and export permissions.

Reference: [Kubernetes Persistent Volumes documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

### 1.6 PVC Mirror Provisioner

CrownLabs' custom **PVC Mirror Provisioner** gives a workload access to an existing volume from another namespace. It creates a mirror PVC in the destination namespace and a new PV that references the original PV's CSI backing volume.

The process is:

1. CrownLabs creates a claim using the `pvc-mirror` StorageClass and identifies the original PVC through `dataSourceRef`.
2. The provisioner checks namespace authorization and validates that the original claim is bound, `ReadWriteMany`, CSI-backed, and mode-compatible.
3. It creates a mirror PV using the original CSI source, mount options, and volume mode.
4. The destination PVC binds to that PV and can be mounted normally by local workloads.

No files are copied or synchronized: the original and mirror PVs expose the same backend allocation. My Drive keeps one mirror in the Tenant namespace; SharedVolumes use the same mechanism with Instance-specific mirrors.

Sources: [mirror claim construction][storage-forge], [mirror provisioner][pmp], [My Drive reconciliation][mydrive-controller], and [SharedVolume mirrors][shared-mirrors].

### 1.7 Concurrent filesystem access

Multiple VMs and the file manager can mount the same My Drive mirror PVC in the Tenant namespace. The claim uses `ReadWriteMany`, and the network filesystem supports shared access.

Each VM Template must explicitly enable `mountMyDriveVolume`. Enabled VMs receive a VirtioFS view of the same backend files, so applications must coordinate concurrent or conflicting writes themselves.

Sources: [My Drive access mode][storage-forge] and [VM attachment construction][vm-forge].


[storage-doc]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/infrastructure/storage-provisioning/README.md
[nfs-sc]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/infrastructure/storage-provisioning/nfs-manifests/storageclass.yaml
[namespace-forge]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/forge/namespace.go
[mydrive-controller]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/controller/tenant/mydrive.go
[storage-forge]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/forge/storage.go
[pmp]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/controller/pmp/provisioner.go
[shared-mirrors]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/instctrl/storage.go
[vm-forge]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/forge/virtualmachines.go
[cloudinit]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/operators/pkg/forge/cloudinit.go
[frontend-create]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/frontend/src/graphql-components/mutation/createInstance.mutation.graphql
[frontend-mydrive]: https://github.com/netgroup-polito/CrownLabs/blob/ce16db0be390f1245f8e0db599310c43a8c6bf1d/frontend/src/components/activePage/DriveView/useMydrive.ts
