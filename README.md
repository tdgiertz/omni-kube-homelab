# Prerequisites
- [brew](https://docs.brew.sh/Homebrew-on-Linux)
  - sudo apt-get install build-essential procps curl file git
  - mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C homebrew
  - Add to .bashrc: eval "$(homebrew/bin/brew shellenv)"
  - Add to .bashrc: export PATH="$HOME/homebrew/bin:$PATH"
  - brew update --force --quiet
  - chmod -R go-w "$(brew --prefix)/share/zsh"
- [sidero](https://github.com/siderolabs/homebrew-tap) 
  - brew install siderolabs/tap/talosctl
  - brew install siderolabs/tap/omnictl
- [wslu](https://wslutiliti.es/wslu/install.html)
  - sudo apt install gnupg2 apt-transport-https
  - wget -O - https://pkg.wslutiliti.es/public.key | sudo gpg -o /usr/share/keyrings/wslu-archive-keyring.pgp --dearmor
  - echo "deb [signed-by=/usr/share/keyrings/wslu-archive-keyring.pgp] https://pkg.wslutiliti.es/debian \
  - $(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/wslu.list
  - sudo apt update
  - sudo apt install wslu
  - Add export BROWSER=wslview to $HOME/.bashrc
- talosctl --talosconfig talos-homelab-talosconfig.yaml --nodes \<IP Address> dashboard
- omnictl --omniconfig omniconfig.yaml get clusters
- brew install int128/kubelogin/kubelogin ([use-kubectl-with-omni](https://omni.siderolabs.com/how-to-guides/use-kubectl-with-omni))
- [ArgoCD Cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
  - brew install argocd
  - or
  - curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
  - sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
  - rm argocd-linux-arm64
- brew install kustomize
- brew install yq
- brew install sops
- brew install helm

## Setup
- Create Age key
  - age-keygen -o age.agekey
  - cp age.agekey ~/.config/sops/age/keys.txt
  - Update public key in .sops.yaml
- Update the secrets and encrypt
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