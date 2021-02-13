#! /bin/bash

set -eu

OLM_LATEST_RELEASE=${OLM_LATEST_RELEASE:=v0.17.0}
TMP_DIR=$(mktemp -d)

kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_LATEST_RELEASE}/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_LATEST_RELEASE}/olm.yaml

git clone https://github.com/operator-framework/operator-marketplace "${TMP_DIR}"
kubectl apply -f "${TMP_DIR}"/deploy/upstream/

trap 'rm -rf "${TMP_DIR}"' EXIT
