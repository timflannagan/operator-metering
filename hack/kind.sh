#! /bin/bash

set -eou pipefail

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")/..

# TODO(tflannag): Need to check if we need to install kind
# TODO(tflannag): Need to run `kind create cluster`.
# TODO(tflannag): Need to run `kind load image ...`

if ! kubectl get namespace olm >/dev/null 2>&1; then
    echo "Installing the upstream OLM..."
    # shellcheck disable=SC1090
    source "${ROOT_DIR}/hack/upstream/install-upstream-olm.sh"
fi

if ! kubectl get namespace monitoring >/dev/null 2>&1; then
    echo "Installing kube-prometheus..."
    # shellcheck disable=SC1090
    source "${ROOT_DIR}/hack/upstream/install-kube-prometheus.sh"
fi

if [ -n "${IMAGE_FORMAT:-}" ]; then
    TEST_IMAGE_REPO="${IMAGE_FORMAT%:*}"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-ansible-operator"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-reporting-operator"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-presto"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-hadoop"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-ghostunnel"
    kind load docker-image "${TEST_IMAGE_REPO}:metering-hive"
fi

#
# Override default variables defined in the e2e.sh bash script
#
export METERING_OLM_MARKETPLACE_NAMESPACE="${METERING_NAMESPACE}"
export METERING_GENERATE_TEST_NAMESPACES="false"
export EXTRA_TEST_FLAGS="-run TestManualMeteringInstall/kind"
export METERING_ANSIBLE_OPERATOR_INDEX_IMAGE="quay.io/tflannag/index:chain"

# shellcheck disable=SC1090
source "${ROOT_DIR}/hack/e2e.sh"

# Welp the `marketplace` namespace that gets created from the OLM release manifests
# does not behave the same ways as the `openshift-marketplace` in OKD environments.
# This is because the OKD-equivalent is treated as a "global" namespace, and the result
# for upstream deployments is that subscriptions need to live in the `marketplace` namespace
# in order to be installed correctly. Else, you run into a subscription reporting a
# `UnhealthyCatalogSourceFound` status in the Subscription resource.
#
# In the context of our e2e suite, we currently don't have any logic that allows us to
# create a metering test installation w/o using that namespace prefix. We can control
# how many installations get created using the `$EXTRA_TEST_FLAGS` argument and passing
# a single sub-test to the `go run test ...` call in hack/e2e.sh.
