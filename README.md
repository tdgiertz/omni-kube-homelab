# Prerequisites

Install [Omni](https://github.com/siderolabs/omni) using [this](https://omni.siderolabs.com/how-to-guides/self_hosted/index) guide.

Create the machine classes in Omni. The machine classes in [machine-class.yaml](machine-class.yaml) define a controller as a node with 8GB of memory and a worker as a node with 16GB or more of memory. Worker nodes are split up into two categories, NVMe and SDB. These two categories are manually applied with labels either via the installation media or by adding a label to the machine in the Omni UI. The machine class is used within the [template.yaml](template.yaml) to create mountpoints for use later by Longhorn.
```bash
omnictl apply -f machine-class.yaml
```
Install [brew](https://docs.brew.sh/Homebrew-on-Linux)
- amd64
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- arm64 ([unsupported](https://docs.brew.sh/Homebrew-on-Linux#arm-unsupported))
```bash
sudo apt-get install build-essential procps curl file git
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C homebrew
echo 'eval "$(homebrew/bin/brew shellenv)"' >> ~/.bashrc
echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> ~/.bashrc
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
```
Install talosctl & omnictl [sidero](https://github.com/siderolabs/homebrew-tap) & ([use-kubectl-with-omni](https://omni.siderolabs.com/how-to-guides/use-kubectl-with-omni))
```bash
brew install siderolabs/tap/talosctl
brew install siderolabs/tap/omnictl
brew install int128/kubelogin/kubelogin
```
Download talosconfig & omniconfig from the Omni UI and confirm set up is working
```bash
talosctl --talosconfig talosconfig.yaml --nodes \<Node IP Address> dashboard
omnictl --omniconfig omniconfig.yaml get clusters
```
Install [wslu](https://wslutiliti.es/wslu/install.html) - Utilities for Windows Subsystem for Linux
```bash
sudo apt install gnupg2 apt-transport-https
wget -O - https://pkg.wslutiliti.es/public.key | sudo gpg -o /usr/share/keyrings/wslu-archive-keyring.pgp --dearmor
echo "deb [signed-by=/usr/share/keyrings/wslu-archive-keyring.pgp] https://pkg.wslutiliti.es/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/wslu.list
sudo apt update
sudo apt install wslu
echo 'export BROWSER=wslview' >> ~/.bashrc
```
Install [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
Option 1: brew
```bash
brew install argocd
```
Option 2:
- amd64
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```
- arm64
```bash
curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
rm argocd-linux-arm64
```
Install additional command line utilities
```bash
brew install kustomize
brew install yq
brew install sops
brew install helm
```

# Components
- [ksops](https://github.com/viaduct-ai/kustomize-sops) - A [sops](https://github.com/getsops/sops) implementation using Kustomize and ArgoCD deployed using a [patch](_initial-setup/patches/argocd/argo-cd-repo-server-ksops-patch.yaml). Secrets are encrypted locally using [Age](https://github.com/FiloSottile/age) and committed to the git repo. ArgoCD uses the private key stored in the cluster to decrypt the secrets and create the Kubernetes secrets.
- [Cilium](https://cilium.io/) - CNI, LB, KubeProxy replacement using either L2 announcements or BGP as configured with use_cilium_bgp in [setup.sh]( _initial-setup/setup.sh)
- [Istio](https://istio.io/) - Gateway API & service mesh enabled (Cilium can be used for gateway API as well, however, it currently lacks support for the TCPRoute which is used for accessing Postgres outside of the cluster).
- [Kiali](https://kiali.io/) - Istio Service Mesh visualization
- [Longhorn](https://longhorn.io/) - CSI for distributed node storage
- [Cert-Manager](https://cert-manager.io/) - Management of certificates used with the gateway API
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) - Bootstrap and continuously deploy apps from git
- [CloudNativePG](https://cloudnative-pg.io/) - Postgres operator
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- node-identifier - App for testing the configuration and load balancing. It returns the node and pod name (on which the request was handled) formatted as JSON.

# Folder structure (also see [here](_initial-setup/README.md))
```sh
📁 _initial-setup    # All manifests used by the cluster through apps and patches
├──📁 config         # Manifests to be configured before copying to the deployment folder
├──📁 patches        # Manifests in full form to be configured and transformed into a Talos patch
📁 deployment        # Directory watched by ArgoCD to deploy applications
│  └──📁 apps        # Application manifests specific to the ArgoCD project "apps"
📁 patches           # Patches applied through Omni to the cluster
```

# Configuration & cluster setup
Create the Age key for use with [ksops](https://github.com/viaduct-ai/kustomize-sops) (Note: replace public key in .sops.yaml)
```bash
age-keygen -o age.agekey
cp age.agekey ~/.config/sops/age/keys.txt
```
Update the values within the manifests in the [config](_initial-setup/config) folder and [setup.sh](_initial-setup/setup.sh), run setup.sh and commit the files updated in the [deployment](deployment) folder to git.

Setup.sh will handle copying manifests from the [config](_initial-setup/config) folder, changing values and encrypting secrets (secret.enc.yaml). The deployment folder will be watched by ArgoCD setup within the [bootstrap](_initial-setup/patches/argocd/bootstrap-app-set.yaml) manifest.
```bash
chmod u+x _initial-setup/setup.sh
./_initial-setup/setup.sh
```
Create the cluster
```bash
omnictl cluster template sync --file template.yaml
```
Create a secret in Kubernetes with the Age private key once nodes have passed the booting state
```bash
cat ~/.config/sops/age/keys.txt | kubectl --kubeconfig kubeconfig.yaml create secret generic sops-age --namespace=argocd --from-file=keys.txt=/dev/stdin
```

Get the initial admin password for ArgoCD
```bash
argocd --kubeconfig ./kubeconfig.yaml admin initial-password -n argocd
```
Get token for Kubernetes Dashboard login
```bash
kubectl  --kubeconfig kubeconfig.yaml get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```