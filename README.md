# Prerequisites

Install [Omni](https://github.com/siderolabs/omni) using [this](https://omni.siderolabs.com/how-to-guides/self_hosted/index) guide.

Create the machine classes in Omni. The machine classes in [machine-class.yaml](machine-class.yaml) define a controller as a node with 8GB of memory and a worker as a node with 16GB or more of memory. Worker nodes are split up into two categories, NVMe and SDB. These two categories are manually applied with labels either via the installation media or by adding a label to the machine in the Omni UI. The machine class is used within the [template.yaml](template.yaml) to create countpoints for use later by Longhorn.
```bash
omnictl apply -f machine-class.yaml
```
Install [brew](https://docs.brew.sh/Homebrew-on-Linux)
- amd64
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- arm64 workaround
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
Install [ArgoCD Cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
Option 1: brew
```bash
brew install argocd
```
Option 2:
- amd64
```bash
curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
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
- [ksops](https://github.com/viaduct-ai/kustomize-sops) - A [sops](https://github.com/getsops/sops) implementation using Kustomize and ArgoCD deployed using a [patch](_manifests/patches/kustomize/argocd/argo-cd-repo-server-ksops-patch.yaml). Secrets are encrypted locally using [Age](https://github.com/FiloSottile/age) and commited to the git repo. ArgoCD uses the private key stored in the cluster to decrypt the secrets and create the Kubernetes secrets.
- [Cilium](https://cilium.io/) - CNI, LB, KubeProxy replacement using either L2 announcements or BGP as configured with use_cilium_bgp in [apply.sh]( _manifests/apply.sh)
- [Istio](https://istio.io/) - Gateway API & service mesh enabled (Cilium can be used for gateway API as well however, it currently lacks support for the TCPRoute which is used for accessing Postgres outside of the cluster).
- [Kiali](https://kiali.io/) - Istio Service Mesh visualization
- [Longhorn](https://longhorn.io/) - CSI for distributed node storage
- [Cert-Manager](https://cert-manager.io/) - Management of certificates used with the gateway API
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) - Bootstrap and continuously deploy apps from git
- [CloudNativePG](https://cloudnative-pg.io/) - Postres operator
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- node-identifier - App for testing the configuration and load balancing. It returns the node and pod name (on which the request was handled) formatted as JSON.

# Folder structure (also see [here](_manifests/README.md))
```sh
📁 _manifests        # All manifests used by the cluster through apps and patches
├──📁 apps           # Manifests in subdirectories are combined and and stored in the deployment folder
│  ├──📁 helm        # Partial set of manifests run through helm template to apply variables
│  └──📁 kustomize   # Static partial set of manifests
├──📁 patches        # Manifests in subdirectories are combined and stored in the patches folder
│  ├──📁 helm        # Partial set of manifests run through helm template to apply variables
│  └──📁 kustomize   # Static partial set of manifests
📁 deployment        # Directory watched by ArgoCD to deploy applications
📁 patches           # Patches applied though Omni to the cluster
```

# Configuration & cluster setup
Create the Age key for use with [ksops](https://github.com/viaduct-ai/kustomize-sops) (Note: replace public key in .sops.yaml)
```bash
age-keygen -o age.agekey
cp age.agekey ~/.config/sops/age/keys.txt
```
Update the values in the [values.yaml](_manifests/apps/helm/values.yaml), run apply.sh and commit the files created in the [deployment](deployment) folder to git.

Apply.sh will handle running helm to combine the templates with values, encrypt secrets (secret.enc.yaml) and move the manifests to the deployment and patches folders. The deployment folder will be watched by ArgoCD setup within the [bootstrap]( _manifests/patches/helm/argocd/templates/bootstrap-app-set.yaml) manifest.
```bash
chmod u+x _manifests/apply.sh
./_manifests/apply.sh
```
Create the cluster
```bash
omnictl cluster template sync --file template.yaml
```
Create a secret in Kubernetes with the Age private key once node have passed the booting state
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