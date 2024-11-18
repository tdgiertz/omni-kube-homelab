Assumes working directory oof kustomize

## ArgoCD

kustomize build ./argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../../patches/argocd.yaml

## ArgoCD HTTP Route

kustomize build ./argocd-http-route > ../argocd/argocd/http-route/http-route.yaml

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

kustomize build ./cilium | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="kube-system"); .contents=load_str("/dev/stdin"))' ../../patches/cilium.yaml

## CloudNativePG

kustomize build ./CloudNativePG > ../argocd/cnpg-system/cnpg/manager.yaml

## Cert-Manager

kustomize build ./cert-manager > ../argocd/cert-manager/cert-manager/cert-manager.yaml

## Istio

kustomize build ./istio > ../argocd/istio-system/istio/istio.yaml

## nginx

kustomize build ./nginx > ../argocd/default/nginx/nginx.yaml

## Istio Gateway

kustomize build ./istio-gateway > ../argocd/default/gateway/gateway.yaml