#!/usr/bin/env bash
set -eEo pipefail 

source run.rc
source common/druid.subr 
source common/azure.subr
source common/utils.subr

__usage="
    -f  filename for the payload
    -x  action to be executed. 
Possible verbs are:
    install        deploy resources.
    delete         delete resources.
"
usage() {
    echo "usage: ${0##*/} [options]"
    echo "${__usage/[[:space:]]/}"
    exit 1
}

# a wrapper around the command to be executed
cmd() {
    echo "\$ ${@}"
    "$@" || echo "[ERROR]: Failed to execute: "$@" "
}

afterboot_info() {
    read -r -d '' COMPLETE_MESSAGE << EOM
****************************************************
[Druid] - Deployment Complete! 
Jump server connection info: ssh $ADMIN_USER_NAME@$JUMP_IP -i $SSH_KEY_PATH/$SSH_KEY_NAME -p 2022
Cluster connection info: http://$CLUSTER_IP_ADDRESS:8081 or http://$CLUSTER_FQDN:8081
****************************************************
EOM
 
  echo "$COMPLETE_MESSAGE" | tee /dev/tty
}

do_install_druid() {
  druid_ns create
  druid_crd create
  druid_operator create
  druid_cluster create
}

do_delete_druid() {
 echo "removing Druid from the Cluster"
 druid_cluster delete
 druid_operator delete
 druid_crd delete
 druid_ns delete
}

do_delete_azure_resources() {
  echo "removing resources in Azure"
  cmd az group delete --name $RG_NAME --no-wait --yes
  
  echo "removing ssh keys"
  rm -rf $SSH_KEY_PATH/$SSH_KEY_NAME.pub
  rm -rf $SSH_KEY_PATH/$SSH_KEY_NAME

  echo "removing logs"
  rm -rf ./outputs
}

# install the Azure resources and Druid
do_install() {
    rg_create
    create_ssh_keys
    load_ssh_keys
    cluster_deploy
    cluster_logs
    aks_get_credentials
    do_install_druid
    afterboot_info
}

# removes the Azure resources and Druid
do_delete() {
  do_delete_druid
  do_delete_azure_resources
}

do_dry_run() {
    # create a random rg so we can dry-run the deployment
    RG_NAME=$RG_NAME-$RANDOM
    rg_create

    create_ssh_keys
    load_ssh_keys
    cluster_dry_run
    do_delete_azure_resources
}

exec_case() {
    local _opt=$1

    case ${_opt} in
    install)            do_install;;
    delete)             do_delete;;
    install-druid)      do_install_druid;;
    delete-druid)       do_delete_druid;;
    dry-run)            do_dry_run;;
    *)                  usage;;
    esac
    unset _opt
}

while getopts "f:o:x:" opt; do
    case $opt in
    f)  _FILENAME="${OPTARG}";;
    o)  _OUTPUT_TYPE="${OPTARG}";;
    x)  exec_flag=true
        EXEC_OPT="${OPTARG}"
        ;;
    *)  usage;;
    esac
done
shift $(( $OPTIND - 1 ))

if [ $OPTIND = 1 ]; then
    usage
    exit 0
fi

if [[ "${exec_flag}" == "true" ]]; then
    exec_case ${EXEC_OPT}
fi

exit 0
