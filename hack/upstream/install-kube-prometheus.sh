#! /bin/bash

set -eu

TMP_DIR=$(mktemp -d)

git clone https://github.com/prometheus-operator/kube-prometheus.git "${TMP_DIR}"

oc apply -f "${TMP_DIR}"/manifests/setup/
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
oc apply -f "${TMP_DIR}"/manifests/

trap 'rm -rf "${TMP_DIR}"' EXIT
