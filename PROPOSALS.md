# Integration Proposals

We have identified four ways to integrate a filesystem-to-object-storage component, we will refeat to it as the **S3 filesystem driver**, it exposes an S3-compatible object store as a filesystem that a virtual machine can mount as **My Drive**. The difference beteeen the approces are mainly in where the driver runs, how many driver instances are required, and how the filesystem is exposed to the guest.

## Proposal 1: install the driver in the virtual-machine image

The S3 filesystem driver is installed directly in each VM image and runs inside the guest. The VM connects to object storage and mounts the resulting filesystem locally.

```text
VM guest → S3 filesystem driver → S3-compatible object storage
```

### Advantages

- The architecture is simple and does not require an additional Kubernetes workload.
- The filesystem is mounted directly in the guest, avoiding an intermediate NFS layer.
- The driver's lifecycle naturally follows the VM's lifecycle.

### Disadvantages

- The user may be able to inspect or modify the endpoint, mount configuration, or credentials.
- Every supported VM image must include and maintain the driver and its configuration.
- Driver updates require rebuilding or updating all affected VM images.
- A user with sufficient privileges inside the VM may stop or reconfigure the driver.

## Proposal 2: install the driver in the `virt-launcher` environment

The S3 filesystem driver runs in the KubeVirt `virt-launcher` pod rather than inside the guest. The mounted filesystem is then exposed to the VM through VirtioFS, following the same final attachment model used by the current My Drive implementation.

```text
S3-compatible object storage
            ↓
S3 filesystem driver in virt-launcher pod
            ↓
         VirtioFS
            ↓
          VM guest
```

### Advantages

- Storage configuration and credentials remain outside the guest.
- The user cannot directly modify the driver process or its endpoint.
- The guest continues to see a normal filesystem through VirtioFS.
- No separate NFS service is required.

### Disadvantages

- Integrating the driver require a custom `virt-launcher` image.
- Customizing a KubeVirt-managed component complicates upgrades and compatibility.
- A driver instance is required for every running VM.
- The feasibility of mounting the driver filesystem and sharing it through VirtioFS must be validated.

## Proposal 3: run one gateway per tenant

A dedicated pod runs the S3 filesystem driver and an NFS server for each tenant. All of the tenant's VMs connect to that service and mount the exported filesystem.

```text
S3-compatible object storage
            ↓
Tenant gateway pod
  ├─ S3 filesystem driver
  └─ NFS server
            ↓
      Tenant's VMs
```

### Advantages

- Only one gateway is required per tenant, regardless of the number of VMs.
- Storage configuration and credentials remain outside the guests.
- Driver updates are independent of VM images and KubeVirt images.
- Multiple VMs can access the same tenant filesystem through a familiar network protocol.

### Disadvantages

- The gateway is a single point of failure for all of the tenant's VMs.
- The design adds an NFS layer and an additional network hop.
- The gateway requires service discovery, network-policy enforcement, health checks, and lifecycle management.
- Tenant isolation depends on correct NFS export and network configuration.

## Proposal 4: add a gateway sidecar to every VM pod

Each `virt-launcher` pod receives a sidecar container running the S3 filesystem driver and an NFS server. The corresponding VM accesses the filesystem exported by its local sidecar.

```text
S3-compatible object storage
            ↓
Per-VM sidecar
  ├─ S3 filesystem driver
  └─ NFS server
            ↓
          VM guest
```

### Advantages

- Storage configuration and credentials remain outside the guest.
- Each VM has an isolated gateway and failure domain.
- The sidecar lifecycle is tied to the VM pod.
- VM images do not need to include the driver.

### Disadvantages

- Every VM requires both a driver and an NFS server, resulting in the highest resource overhead.
- The NFS layer adds complexity even though the gateway is colocated with the VM.
- Sidecar injection and VM connectivity require integration with KubeVirt-managed pods.
- Multiple VMs belonging to the same tenant do not share a driver instance or cache.