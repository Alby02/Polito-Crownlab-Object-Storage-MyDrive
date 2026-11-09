# k3s cluster on CrownLabs (Ansible)

3-node [k3s](https://k3s.io) cluster on CrownLabs Fedora VMs, installed with the
official [`k3s.orchestration`](https://github.com/k3s-io/k3s-ansible) collection.

| Host  | CrownLabs instance                         | Role                                   |
|-------|--------------------------------------------|----------------------------------------|
| node1 | `instance-gdxjn-k3s-node1.tenant-s360540`  | server (bootstraps the etcd cluster)   |
| node2 | `instance-gdxjn-k3s-node2.tenant-s360540`  | server                                 |
| node3 | `instance-gdxjn-k3s-node3.tenant-s360540`  | server                                 |

All nodes are k3s **servers**: HA control plane on embedded etcd (survives 1 node
down) and, since k3s servers are not tainted, every node also runs workloads.

All SSH goes through the bastion `bastion@ssh-preprod.crownlabs.polito.it` (see `inventory/hosts.yml`).

## Layout

```
ansible.cfg          # defaults: inventory path, local collections dir, SSH multiplexing
requirements.yml     # Ansible collections to install
inventory/hosts.yml  # nodes, groups (server/agent) and k3s settings
site.yml             # install k3s + fetch kubeconfig locally
```

## Usage

Run from this directory.

```bash
# Local requirements (the controller needs netaddr for the k3s collection)
sudo dnf install ansible python3-netaddr
ansible-galaxy collection install -r requirements.yml

ansible all -m ping                       # check connectivity
ansible-playbook site.yml                 # install / reconcile the cluster (idempotent)
ansible-playbook k3s.orchestration.reset  # uninstall k3s from all nodes
ansible-playbook k3s.orchestration.upgrade  # after bumping k3s_version in the inventory
```

## Using kubectl

Either run it on the server:

```bash
ssh -J bastion@ssh-preprod.crownlabs.polito.it crownlabs@instance-gdxjn-k3s-node1.tenant-s360540
kubectl get nodes
```

or from your machine, through an SSH tunnel (`site.yml` writes `./kubeconfig.yaml` pointing at `127.0.0.1:6443`):

```bash
ssh -N -L 6443:127.0.0.1:6443 -J bastion@ssh-preprod.crownlabs.polito.it \
    crownlabs@instance-gdxjn-k3s-node1.tenant-s360540 &
KUBECONFIG=$PWD/kubeconfig.yaml kubectl get nodes
```

## CrownLabs-specific notes

- **SELinux** is enforcing on Fedora: k3s runs with `selinux: true` and the
  `k3s-selinux` RPM is installed by the k3s install script.
- **Flannel uses `wireguard-native`** instead of the default VXLAN: VXLAN traffic
  between CrownLabs VMs is dropped (pods on different nodes cannot talk), while
  WireGuard over UDP 51820 works.
- **Use the FQDN `<instance>.<tenant>.svc.crowng`** for node-to-node addressing:
  inside the VMs the short `<instance>.<tenant>` name does not resolve reliably.
- VM interface MTU is 1340; flannel derives the overlay MTU automatically.
- **etcd members are registered by IP.** If CrownLabs gives a VM a new IP after a
  restart, that member will fail to rejoin; reset and reinstall the cluster
  (`k3s.orchestration.reset` then `site.yml`).
- **Changing a node's role** (agent <-> server): run `k3s.orchestration.reset`
  *before* editing the inventory, since reset picks the uninstall script
  (`k3s-uninstall.sh` vs `k3s-agent-uninstall.sh`) based on the current group.
