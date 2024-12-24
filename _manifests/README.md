## Manifest directory structure

### [apply.sh](apply.sh)

Comines the result of helm templating with the static manifests and saves to the deployment and patches folders.

### [Apps](apps)

This folder contains all of the manifests for apps that are watched by ArgoCD and created via bootstrapping within the ArgoCD ApplicationSet. There are two subdirectories 'helm' and 'kustomize' that are combined into the deployment folder when running [apply.sh](apply.sh). The folder 'helm' contains a chart that is used to apply [values yaml](apps/helm/values.yaml) to any files with variables. The folder 'kustomize' contains all of the static files that are copied to the deployment folder verbatim.

### [Patches](patches)

This folder contains all of the manifests that create patches used in the Omni template.yaml for cluster creation. The projects in the directory are combined with each matching chart under the helm folder using the same [values yaml](apps/helm/values.yaml) for the apps. The [cilium-bgp](patches/kustomize/cilium-bgp) and [cilium-l2](patches/kustomize/cilium-l2) are mutually exclusive. The project is selected via the use_cilium_bgp variable within [apply.sh](apply.sh).