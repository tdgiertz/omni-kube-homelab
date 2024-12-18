# Prerequisites
## Install [brew](https://docs.brew.sh/Homebrew-on-Linux)
```bash
sudo apt-get install build-essential procps curl file git
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C homebrew
echo 'eval "$(homebrew/bin/brew shellenv)"' >> ~/.bashrc
echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> ~/.bashrc
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
```
## Install talosctl & omnictl [sidero](https://github.com/siderolabs/homebrew-tap) & ([use-kubectl-with-omni](https://omni.siderolabs.com/how-to-guides/use-kubectl-with-omni))
```bash
brew install siderolabs/tap/talosctl
brew install siderolabs/tap/omnictl
brew install int128/kubelogin/kubelogin
```
## Download talosconfig & omniconfig from Omni and confirm set up is working
```bash
talosctl --talosconfig talosconfig.yaml --nodes \<IP Address> dashboard
omnictl --omniconfig omniconfig.yaml get clusters
```
## Install [wslu](https://wslutiliti.es/wslu/install.html) - Utilities for Windows Subsystem for Linux
```bash
sudo apt install gnupg2 apt-transport-https
wget -O - https://pkg.wslutiliti.es/public.key | sudo gpg -o /usr/share/keyrings/wslu-archive-keyring.pgp --dearmor
echo "deb [signed-by=/usr/share/keyrings/wslu-archive-keyring.pgp] https://pkg.wslutiliti.es/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/wslu.list
sudo apt update
sudo apt install wslu
echo 'export BROWSER=wslview' >> ~/.bashrc
```
## Install [ArgoCD Cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
### Option 1: brew
```bash
brew install argocd
```
### Option 2: amd64
```bash
curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```
### or arm64
```bash
curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
rm argocd-linux-arm64
```
## Install additional command line utilities
```bash
brew install kustomize
brew install yq
brew install sops
brew install helm
```

# Setup
## Create Age key
```bash
age-keygen -o age.agekey
cp age.agekey ~/.config/sops/age/keys.txt
```
### Replace public key in .sops.yaml
## Update the secrets and encrypt
  - Postgres user
  - Minio for Longhorn
  - Cert-Manager issuer and api token
```bash
sops --encrypt --in-place secret.enc.yaml
```
- Create Omni self hosted instance
- Create machine classes in Omni
```bash
omnictl apply -f machine-class.yaml
```
- Create the cluster
```bash
omnictl cluster template sync --file template.yaml
```
- Create a secret in Kubernetes with the Age private key
```bash
cat ~/.config/sops/age/keys.txt | kubectl --kubeconfig kubeconfig.yaml create secret generic sops-age --namespace=argocd --from-file=keys.txt=/dev/stdin
```

- Get token for Kubernetes Dashboard login
```bash
kubectl  --kubeconfig kubeconfig.yaml get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```