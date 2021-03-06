#!/bin/sh

USAGE="Usage: $0 <PLAYBOOK> <OPENSHIFT_PROVISION_CLUSTER_NAME>"
PLAYBOOK="$1"
export OPENSHIFT_PROVISION_CLUSTER_NAME="${2:-$OPENSHIFT_PROVISION_CLUSTER_NAME}"

errexit () {
  echo -e "$1\n$USAGE" >&2
  exit 1
}

[[ -z "$PLAYBOOK" ]] && errexit "No PLAYBOOK provided."
[[ -z "$OPENSHIFT_PROVISION_CLUSTER_NAME" ]] && errexit "No OPENSHIFT_PROVISION_CLUSTER_NAME provided."

# Path to the cluster config
export OPENSHIFT_PROVISION_CONFIG_PATH=${OPENSHIFT_PROVISION_CONFIG_PATH:-$PWD/../config}

# Directory within OPENSHIFT_PROVISION_CONFIG_PATH of the cluster config directoriy
OPENSHIFT_CLUSTER_DIR=${OPENSHIFT_PROVISION_CONFIG_PATH}/cluster/${OPENSHIFT_PROVISION_CLUSTER_NAME}

# Location of openshift-provision-demo to copy over to controller instance
OPENSHFIT_PROVISION_DEMO_DIR=$(dirname $PWD)

[[ -d "$OPENSHIFT_PROVISION_CONFIG_PATH" ]] || \
  errexit "OPENSHIFT_PROVISION_CONFIG_PATH not found at $OPENSHIFT_PROVISION_CONFIG_PATH"
[[ -d "$OPENSHIFT_CLUSTER_DIR" ]] || \
  errexit "Cluster subdirectory not found at $OPENSHIFT_CLUSTER_DIR"

ANSIBLE_VARS="\
--inventory=../hosts.py \
-e openshift_provision_cluster_name=$OPENSHIFT_PROVISION_CLUSTER_NAME \
-e openshift_provision_demo_path=$OPENSHFIT_PROVISION_DEMO_DIR \
-e openshift_provision_config_path=$OPENSHIFT_PROVISION_CONFIG_PATH"

export ANSIBLE_ROLES_PATH=$OPENSHFIT_PROVISION_DEMO_DIR/roles

ansible-playbook $ANSIBLE_VARS $PLAYBOOK
