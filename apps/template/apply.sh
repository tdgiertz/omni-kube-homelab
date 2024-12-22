#!/usr/bin/env bash
cd "$(dirname "$0")"

SUBDOMAIN="apps.timgiertz.com"
DEPLOYMENT_DIR=../../deployment
APPS_DIR="$DEPLOYMENT_DIR/apps"

if [ -d "$APPS_DIR" ]; then
    rm -r "$APPS_DIR"
fi

cp -r apps "$DEPLOYMENT_DIR"

find "$APPS_DIR" -type f -name "*.yaml" -print0 | xargs -0 sed -i "s/{subdomain}/$SUBDOMAIN/g"
