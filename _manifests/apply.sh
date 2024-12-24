#!/usr/bin/env bash

cd "$(dirname "$0")"

use_cilium_bgp=true
output_dir=..
deployment_dir=../deployment
apps_dir="$deployment_dir/apps"
templates_dir="$deployment_dir/templates"
helm_values=./apps/helm/values.yaml

mkdir -p "$templates_dir/apps"

if [ -d "$apps_dir" ]; then
    rm -r "$apps_dir"
fi

echo "Creating apps directory"
cp -r apps/kustomize/* "$templates_dir/apps"

helm template --no-hooks --name-template 'deployment' -f $helm_values ./apps/helm --output-dir "$output_dir"

mv "$templates_dir/apps" "$apps_dir"

rm -r "$templates_dir"

sops --encrypt --in-place "$apps_dir/cert-manager/secret.enc.yaml"
sops --encrypt --in-place "$apps_dir/longhorn/secret.enc.yaml"
sops --encrypt --in-place "$apps_dir/postgres/secret.enc.yaml"

templateAndBuild() {
	helm template --no-hooks --name-template "$1" -f $helm_values ./patches/helm/$2 --output-dir "$temp_dir"
	mv $templates_dir/* $3
	rm -r "$templates_dir"
	cp -r patches/$2/* $3
	kustomize build $3 | yq -i "with(.cluster.inlineManifests.[] | select(.name==\"$4\"); .contents=load_str(\"/dev/stdin\"))" ../patches/$5
}

temp_dir="patches/.tmp"
argocd_dir="$temp_dir/argocd/"
templates_dir="$argocd_dir/templates"

echo "Creating argocd patch"
templateAndBuild "argocd" "argocd" $argocd_dir "argocd" "argocd.yaml"

cilium_dir="$temp_dir/cilium"
cilium_folder="cilium_l2"
templates_dir="$cilium_dir/templates"

echo "Creating cilium patch"
if [ use_cilium_bgp ]; then
    cilium_folder="cilium-bgp"
fi

templateAndBuild "cilium" $cilium_folder $cilium_dir "kube-system" "cilium.yaml"

rm -r $temp_dir

echo "Creating istio patch"
kustomize build patches/istio | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="istio"); .contents=load_str("/dev/stdin"))' ../patches/istio.yaml