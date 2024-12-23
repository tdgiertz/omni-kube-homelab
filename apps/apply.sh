#!/usr/bin/env bash
cd "$(dirname "$0")"

pwd

# SUBDOMAIN="apps.timgiertz.com"
OUTPUT_DIR=..
DEPLOYMENT_DIR=../deployment
APPS_DIR="$DEPLOYMENT_DIR/apps"
TEMPLATES_DIR="$DEPLOYMENT_DIR/templates"

ls "$DEPLOYMENT_DIR"

mkdir -p "$TEMPLATES_DIR"

if [ -d "$APPS_DIR" ]; then
    rm -r "$APPS_DIR"
fi

cp -r apps "$TEMPLATES_DIR"

# find "$APPS_DIR" -type f -name "*.yaml" -print0 | xargs -0 sed -i "s/{subdomain}/$SUBDOMAIN/g"

helm template --no-hooks --name-template 'deployment-chart' -f values.yaml . --output-dir "$OUTPUT_DIR"

mv "$TEMPLATES_DIR/apps" "$APPS_DIR"

rm -r "$TEMPLATES_DIR"

sops --encrypt --in-place "$APPS_DIR/cert-manager/secret.enc.yaml"
sops --encrypt --in-place "$APPS_DIR/longhorn/secret.enc.yaml"
sops --encrypt --in-place "$APPS_DIR/postgres/secret.enc.yaml"