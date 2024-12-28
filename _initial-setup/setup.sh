#!/usr/bin/env bash

cd "$(dirname "$0")"

use_cilium_bgp=true
hostname="apps.timgiertz.com"
repoBranch="main"
repoPath="deployment/*/*"
repoURL="https://github.com/tdgiertz/omni-kube-homelab.git"

copyFromTo=(
    '{ "copyFrom": "./config/cert-manager-secret.yaml", "copyTo": "../deployment/apps/cert-manager/overlays/prod/secret.enc.yaml" }'
    '{ "copyFrom": "./config/longhorn-secret.yaml", "copyTo": "../deployment/apps/longhorn/overlays/prod/secret.enc.yaml", "base64CheckPaths": [".data.AWS_ACCESS_KEY_ID", ".data.AWS_SECRET_ACCESS_KEY", ".data.AWS_ENDPOINTS"]}'
    '{ "copyFrom": "./config/postgres-secret.yaml", "copyTo": "../deployment/apps/postgres/overlays/prod/secret.enc.yaml" }'
)

isBase64EncodedRegex="^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$"

for element in "${copyFromTo[@]}"; do
    copyFrom=$(echo "$element" | jq -r '.copyFrom')
    copyTo=$(echo "$element" | jq -r '.copyTo')

    cat $copyFrom > $copyTo

    # Check each path for each element and replace the value with a base64 encoded value if it isn't already encoded
    if echo "$element" | jq -e ".base64CheckPaths?" > /dev/null; then
        base64CheckString=$(echo "$element" | jq -r '.base64CheckPaths')
        readarray -t base64Checks < <(echo "$base64CheckString" | jq -r '.[]')

        for checkPath in "${base64Checks[@]}"; do
            valueFromFile=$(yq $checkPath $copyTo)

            if ! [[ "$valueFromFile" =~ $isBase64EncodedRegex ]]; then
                encodedString=$(echo -n "$valueFromFile" | base64)
                yq "${checkPath}=\"$encodedString\"" -i $copyTo
            fi
        done
    fi

    sops --encrypt --in-place $copyTo

    # Find all files in deployment/apps/../overlays/prod and replace the domain
    find ../deployment/apps -path "*overlays/prod*" -type f | while read -r file; do
        sed -i "s/apps.example.com/${hostname}/g" $file
    done

done

escapeString() {
	echo $(printf '%s\n' "$1" | sed -e 's/[\/&]/\\&/g')
}

escapedRepoBranch=$(escapeString "$repoBranch")
escapedRepoPath=$(escapeString "$repoPath")
escapedRepoURL=$(escapeString "$repoURL")

echo "Creating ArgoCD patch"
kustomize build patches/kustomize/argocd \
    | sed -e "s/branch: branch/branch: ${escapedRepoBranch}/g" \
          -e "s/repoPath: repoPath/repoPath: ${escapedRepoPath}/g" \
          -e "s/repoURL: repoURL/repoURL: ${escapedRepoURL}/g" \
          -e "s/apps.example.com/${hostname}/g" \
    | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../patches/argocd.yaml

cilium_folder="cilium_l2"

echo "Creating cilium patch"
if [ use_cilium_bgp ]; then
    cilium_folder="cilium-bgp"
fi

kustomize build patches/kustomize/$cilium_folder \
    | sed -e "s/apps.example.com/${hostname}/g" \
    | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="kube-system"); .contents=load_str("/dev/stdin"))' ../patches/cilium.yaml

echo "Creating Istio patch"
kustomize build patches/kustomize/istio | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="istio"); .contents=load_str("/dev/stdin"))' ../patches/istio.yaml