## Initial-setup directory structure

The contents can be used to configure a new cluster, update a cluster or just learn the locations of manifests to configure.

### [setup.sh](setup.sh)

Applies the values defined in setup.sh to the [config](config) and [patches](patches) folders and updates the manifests in the [deployment/apps](../deployment/apps) and [patches](../patches) folders.

### [update.sh](patches/update.sh)

Runs helm template for select charts and updates the static manifests.

### [Config](config)

This folder contains any manifests to be copied to the [deployment/apps](../deployment/apps) folder. The values are configured with the [setup.sh](setup.sh) script and then written to the [deployment/apps](../deployment/apps) folder through the same script.

### [Patches](patches)

This folder contains all of the manifests that create patches used in the Omni template.yaml for cluster creation. The values are configured with the [setup.sh](setup.sh) script and then written to the [patches](../patches) folder through the same script.

The [cilium-bgp](patches/cilium-bgp) and [cilium-l2](patches/cilium-l2) are mutually exclusive. The project is selected via the use_cilium_bgp variable within [setup.sh](setup.sh) script.