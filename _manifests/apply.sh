#!/usr/bin/env bash

cd "$(dirname "$0")"

use_cilium_bgp=true
output_dir=..
deployment_dir=../deployment
apps_dir="$deployment_dir/apps"
templates_dir="$deployment_dir/templates"
helm_values=./apps/helm/values.yaml

mkdir -p "$templates_dir"

if [ -d "$apps_dir" ]; then
    rm -r "$apps_dir"
fi

echo "Creating apps directory"
cp -r apps/helm "$templates_dir"

helm template --no-hooks --name-template 'deployment' -f $helm_values ./apps/helm --output-dir "$output_dir"

mv "$templates_dir/apps" "$apps_dir"

rm -r "$templates_dir"

sops --encrypt --in-place "$apps_dir/cert-manager/secret.enc.yaml"
sops --encrypt --in-place "$apps_dir/longhorn/secret.enc.yaml"
sops --encrypt --in-place "$apps_dir/postgres/secret.enc.yaml"

echo "Creating cilium patch"
if [ use_cilium_bgp ]; then
    kustomize build ./patches/cilium-bgp | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="kube-system"); .contents=load_str("/dev/stdin"))' ../patches/cilium.yaml
else
    kustomize build ./patches/cilium-l2 | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="kube-system"); .contents=load_str("/dev/stdin"))' ../patches/cilium.yaml
fi

temp_dir="patches/.tmp"
argocd="$temp_dir/argocd/"
templates_dir="$argocd/templates"

echo "Creating argocd patch"
helm template --no-hooks --name-template 'argocd' -f $helm_values ./patches/templates/argocd --output-dir "$temp_dir"

mv $templates_dir/* $argocd

rm -r "$templates_dir"

cp -r patches/argocd/* $argocd

kustomize build $argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../patches/argocd.yaml

rm -r $temp_dir

echo "Creating istio patch"
kustomize build patches/istio | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="istio"); .contents=load_str("/dev/stdin"))' ../patches/istio.yaml