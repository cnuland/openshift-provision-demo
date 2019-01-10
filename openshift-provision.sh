#!/bin/sh

USAGE="Usage: $0 <CLUSTER_NAME>"
OPENSHIFT_PROVISION_CLUSTER_NAME="$1"

errexit () {
  echo -e "$1\n$USAGE" >&2
  exit 1
}

[[ -z "$OPENSHIFT_PROVISION_CLUSTER_NAME" ]] && errexit "No OPENSHIFT_PROVISION_CLUSTER_NAME provided."

OPENSHIFT_PROVISION_CONFIG_PATH=${OPENSHIFT_PROVISION_CONFIG_PATH:-$PWD/config}
OPENSHIFT_PROVISION_CLUSTER_DIR=${OPENSHIFT_PROVISION_CONFIG_PATH}/cluster/${OPENSHIFT_PROVISION_CLUSTER_NAME}
OPENSHIFT_PROVISION_CONNECTION_SETTINGS=${OPENSHIFT_PROVISION_CLUSTER_DIR}/openshift-connection.yml
VAULT_PASSWORD_FILE=${VAULT_PASSWORD_FILE:-$PWD/.vaultpw}

[[ -d "$OPENSHIFT_PROVISION_CONFIG_PATH" ]] || \
  errexit "OPENSHIFT_PROVISION_CONFIG_PATH not found at $OPENSHIFT_PROVISION_CONFIG_PATH"
[[ -d "$OPENSHIFT_PROVISION_CLUSTER_DIR" ]] || \
  errexit "Cluster subdirectory not found at $OPENSHIFT_PROVISION_CLUSTER_DIR"
[[ -f "$OPENSHIFT_PROVISION_CONNECTION_SETTINGS" ]] || \
  errexit "OPENSHIFT_CONNECTION_SETTINGS file not found at $OPENSHIFT_PROVISION_CONNECTION_SETTINGS"
[[ -f "$VAULT_PASSWORD_FILE" ]] || \
  errexit "VAULT_PASSWORD_FILE not found at $VAULT_PASSWORD_FILE"

ANSIBLE_VARS="\
--vault-password-file=$VAULT_PASSWORD_FILE \
-e openshift_provision_cluster_name=$OPENSHIFT_PROVISION_CLUSTER_NAME \
-e openshift_provision_config_path=$OPENSHIFT_PROVISION_CONFIG_PATH \
-e @$OPENSHIFT_CONNECTION_SETTINGS"

export OPENSHIFT_PROVISION_CONFIG_PATH OPENSHIFT_PROVISION_CLUSTER_NAME
ansible-playbook $ANSIBLE_VARS openshift-provision.yml
