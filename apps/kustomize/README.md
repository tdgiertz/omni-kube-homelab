Assumes working directory oof kustomize

## ArgoCD

kustomize build ./argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../../patches/argocd.yaml

## Longhorn

kustomize build ./longhorn > ../argocd/longhorn-system/storage/storage.yaml

## Cilium

helm template \
    cilium \
    cilium/cilium \
    --version 1.16.2 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set=kubeProxyReplacement=true \
    --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set=k8sServiceHost=localhost \
    --set=k8sServicePort=7445 \
    --set=nodeIPAM.enabled=true \
    --set=gatewayAPI.enabled=false \
    --set=envoy.securityContext.capabilities.keepCapNetBindService=true \
    --set=bgpControlPlane.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true > cilium/install-cilium.yaml

kustomize build ./cilium > ../../manifests/install-cilium.yaml

## CloudNativePG

kustomize build ./CloudNativePG > ../argocd/cnpg-system/cnpg/manager.yaml