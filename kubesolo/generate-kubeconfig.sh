#!/usr/bin/env bash

set -o errexit
set -o pipefail

SHELL="/bin/bash"
PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export KUBECONFIG="${KUBECONFIG:-/var/lib/kubesolo/pki/admin/admin.kubeconfig}"

TARGET="${1:-}"

usage() {
    local script
    script=$(basename "${0}")

    cat <<EOF >&2
Error:
  Missing required 'target' parameter

Usage:
  ./${script} <target>

Example:
  ./${script} app
  ./${script} infra

EOF
    exit 1
}

validate_input() {
    if [ -z "${TARGET}" ]; then
        usage
    fi
}

resolve_target_variables() {
    if [ "${TARGET}" = "infra" ]; then
        NAMESPACE="kube-system"
        SECRET="infra-deployer-token"
        USER="infra-deployer"
    else
        NAMESPACE="${TARGET}"
        SECRET="${TARGET}-deployer-token"
        USER="${TARGET}-deployer"
    fi
}

get_cluster_info() {
    ADDRESS=$(kubectl --context=kubernetes-admin@kubesolo get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    PORT=$(kubectl --context=kubernetes-admin@kubesolo config view --minify -o jsonpath='{.clusters[0].cluster.server}' | grep -oE ':[0-9]+$')
    PORT=${PORT:-:6443}
    SERVER="https://${ADDRESS}${PORT}"

    CA_CERT=$(kubectl --context=kubernetes-admin@kubesolo get secret "${SECRET}" -n "${NAMESPACE}" -o jsonpath='{.data.ca\.crt}')
    TOKEN=$(kubectl --context=kubernetes-admin@kubesolo get secret "${SECRET}" -n "${NAMESPACE}" -o jsonpath='{.data.token}' | base64 --decode)
}

render_kubeconfig() {
    cat <<EOF
apiVersion: v1
kind: Config
current-context: default
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${SERVER}
  name: kubesolo
contexts:
- context:
    cluster: kubesolo
    namespace: ${NAMESPACE}
    user: ${USER}
  name: default
users:
- name: ${USER}
  user:
    token: ${TOKEN}
EOF
}

# Establish run order
main() {
    validate_input
    resolve_target_variables
    get_cluster_info
    render_kubeconfig
}

main "${@}"
