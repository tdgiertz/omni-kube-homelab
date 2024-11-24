Assumes working directory of kustomize

## ArgoCD

kustomize build ./argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../../patches/argocd.yaml

## ArgoCD HTTP Route

kustomize build ./argocd-http-route > ../argocd/argocd/http-route/http-route.yaml

## Cert-Manager

kustomize build ./cert-manager > ../argocd/cert-manager/cert-manager/cert-manager.yaml

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
    --set=hubble.relay.enabled=true \
    --set=hubble.ui.enabled=true \
    --set=cni.exclusive=false > cilium/install-cilium.yaml

kustomize build ./cilium | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="kube-system"); .contents=load_str("/dev/stdin"))' ../../patches/cilium.yaml

## CloudNativePG

kustomize build ./CloudNativePG > ../argocd/cnpg-system/cnpg/manager.yaml

## Istio

helm template istio-base istio/base -n istio-system --create-namespace > istio/istio-base.yaml
helm template istiod istio/istiod --namespace istio-system --set profile=ambient --set pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true > istio/istio-control-plane.yaml
helm template istio-cni istio/cni -n istio-system --set profile=ambient > istio/istio-cni.yaml
helm template ztunnel istio/ztunnel -n istio-system > istio/istio-ztunnel.yaml
helm template istio-ingress istio/gateway -n istio-ingress --create-namespace  > istio/istio-gateway.yaml

kustomize build ./istio > ../argocd/istio-system/istio/istio.yaml

## Istio Gateway

kustomize build ./istio-gateway > ../argocd/default/gateway/gateway.yaml

## Kubernetes Dashboard

kustomize build ./kubernetes-dashboard > ../argocd/kubernetes-dashboard/dashboard/dashboard.yaml

## Longhorn

kustomize build ./longhorn > ../argocd/longhorn-system/storage/storage.yaml

## nginx

kustomize build ./nginx > ../argocd/default/nginx/nginx.yaml

## postgres

kustomize build ./postgres > ../argocd/default/postgres/postgres.yaml