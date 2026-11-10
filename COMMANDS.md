kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/v1.9.1/kubevirt-operator.yaml"
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/v1.9.1/kubevirt-cr.yaml"
krew install virt


cd Ansible
ansible all -m shell -a 'ls -l /dev/kvm; grep -cE "vmx|svm" /proc/cpuinfo'

8 Significa Che la nested virtualization funge

kubectl get nodes -o custom-columns=NAME:.metadata.name,KVM:.status.allocatable.devices\\.kubevirt\\.io/kvm
1k significa che kubevirt è configurato correttamente


kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.66.1/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.66.1/cdi-cr.yaml


kubectl create -f ./manifests/dv_fedora.yml

kubectl create -f ./manifests/vm1_pvc.yml

than this:
ssh -J bastion@ssh-preprod.crownlabs.polito.it,crownlabs@instance-gdxjn-k3s-node1.tenant-s360540 fedora@10.42.2.17

or this:

kubectl virt expose vmi vm1 --name=vm1-ssh --port=20222 --target-port=22 --type=NodePort
ssh -N -L 30392:0.0.0.0:30392 -J bastion@ssh-preprod.crownlabs.polito.it crownlabs@instance-gdxjn-k3s-node1.tenant-s360540
ssh fedora@localhost -p 30392