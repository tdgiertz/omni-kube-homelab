Assumes working directory oof kustomize

## ArgoCD

kustomize build ./argocd | yq -i 'with(.cluster.inlineManifests.[] | select(.name=="argocd"); .contents=load_str("/dev/stdin"))' ../../patches/argocd.yaml