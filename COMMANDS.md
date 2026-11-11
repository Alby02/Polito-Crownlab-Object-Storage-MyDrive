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

in endpoin run :

podman run -d \
  --name juicefs-redis \
  --restart unless-stopped \
  -p 6379:6379 \
  -v juicefs-redis-data:/data \
  --health-cmd "redis-cli ping" \
  --health-interval 10s \
  --health-timeout 3s \
  --health-retries 5 \
  docker.io/library/redis:8-alpine \
  redis-server \
    --protected-mode no \
    --appendonly yes \
    --appendfsync everysec \
    --maxmemory-policy noeviction


sudo firewall-cmd --permanent --add-port=6379/tcp --add-port=9000/tcp
sudo firewall-cmd --reload


helmfile init

helmfile apply -f juice-helmfile/helmfile.yaml.gotmpl
kubectl -n kube-system get pods -l app.kubernetes.io/name=juicefs-csi-driver -w


kubectl apply -f juicefs-container/juicefs-pvc.yaml
kubectl apply -f juicefs-container/juicefs-pod-1.yaml
kubectl apply -f juicefs-container/juicefs-pod-2.yaml

kubectl exec -it juicefs-app-1 -- /bin/bash
kubectl exec -it juicefs-app-2 -- /bin/bash


kubectl -n kubevirt patch kubevirt kubevirt --type=merge \
  -p '{"spec":{"configuration":{"developerConfiguration":{"featureGates":["EnableVirtioFsStorageVolumes"]}}}}'


kubectl create -f manifests/vm2_juicefs.yml

kubectl virt expose vmi vm2 --name=vm2-ssh --port=22222 --target-port=22 --type=NodePort
ssh -N -L 31556:0.0.0.0:31556 -J bastion@ssh-preprod.crownlabs.polito.it crownlabs@instance-gdxjn-k3s-node1.tenant-s360540
ssh fedora@localhost -p 31556

