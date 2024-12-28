## Manifest directory structure

### [setup.sh](setup.sh)

Applies the values defined in setup.sh to the [config](config) and [patches](patches) folders and updates the manifests in the [deployment/apps](deployment/apps) and [patches](patches) folders.

### [update.sh](patches/update.sh)

Runs helm template for select charts and updates the static manifests.

### [Config](config)

This folder contains any manifests to be updated with configurable values and then written to the [deployment/apps](deployment/apps) folder through the [setup.sh](setup.sh) script.


### [Patches](patches)

This folder contains all of the manifests that create patches used in the Omni template.yaml for cluster creation. The projects in the directory are combined with each matching chart under the helm folder using the same [values yaml](apps/helm/values.yaml) for the apps. The [cilium-bgp](patches/kustomize/cilium-bgp) and [cilium-l2](patches/kustomize/cilium-l2) are mutually exclusive. The project is selected via the use_cilium_bgp variable within [apply.sh](apply.sh).