helm repo add cilium https://helm.cilium.io/
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kustomize build ./argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../../patches/argocd.yaml

helm template \
    cilium \
    cilium/cilium \
    --version 1.16.4 \
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


helm template istio-base istio/base -n istio-system --create-namespace > ../../deployment/apps/istio/istio-base.yaml
helm template istiod istio/istiod --namespace istio-system --set profile=ambient --set pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true > ../../deployment/apps/istio/istio-control-plane.yaml
helm template istio-cni istio/cni -n istio-system --set profile=ambient > ../../deployment/apps/istio/istio-cni.yaml
helm template ztunnel istio/ztunnel -n istio-system > ../../deployment/apps/istio/istio-ztunnel.yaml
helm template istio-ingress istio/gateway -n istio-ingress --create-namespace  > ../../deployment/apps/istio/istio-gateway.yaml
