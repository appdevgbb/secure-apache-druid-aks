#!/usr/bin/env bash
set -Eo pipefail

source run.rc
source common/druid.subr
source common/azure.subr
source common/utils.subr

########################################################################################
AZURE_LOGIN=0
PURGE=1
########################################################################################
trap exit SIGINT SIGTERM

__usage="
    -o  options
    -x  action to be executed.
    
Possible verbs are:
    install        deploy resources.
    delete         delete resources.
    dry-run        tries the current Bicep deployment against Azure but doesn't deploy (what-if). 

    Apache Druid:
    install-druid  only installs the Apache Druid on the cluster.
    delete-druid   removes Apache Druid from the cluster.

Options:
    KeepSSHKeys    do not remove the SSH keys (used with the -x delete option).

"
usage() {
  echo "usage: ${0##*/} [options]"
  echo "${__usage/[[:space:]]/}"
  exit 1
}

# execute as the last part of the setup process
afterboot() {

  #if AUTHORIZED_HOST_KEYS is set, add SSH Public keys to the authorized_keys file
  if [[ -n "${AUTHORIZED_HOST_KEYS}" ]]; then
    echo "${AUTHORIZED_HOST_KEYS}" | run_on_jumpbox "cat >> ~/.ssh/authorized_keys"
  fi

  read -r -d '' COMPLETE_MESSAGE <<EOM
****************************************************
[Druid] - Deployment Complete! 
Jump server connection info: ssh $ADMIN_USER_NAME@$JUMP_IP -i $SSH_KEY_PATH/$SSH_KEY_NAME

Cluster connection info: 
  export KUBECONFIG=${PREFIX}-aks.kubeconfig
  kubectl get nodes
****************************************************
EOM

  echo "$COMPLETE_MESSAGE"
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
  cmd az group delete --name "${RG_NAME}" --no-wait --yes

  # The default behaviour is to purge the logs and ssh keys.
  # This variable is here to accomodate for when running 
  # through Github Actions. Also don't delete the keys if they 
  # were passed as environment variables
  if [[ ${PURGE} -eq 1 && -z ${SSH_PUB_KEY} ]]; then 
    echo "removing ssh keys"
    load_ssh_keys
    cmd rm "${SSH_KEY_PATH:?}/${SSH_KEY_NAME}.pub"
    cmd rm "${SSH_KEY_PATH:?}/${SSH_KEY_NAME:?}"
  
    echo "removing logs"
    rm -rf ./outputs
  fi
}

# install the Azure resources and Druid
do_install() {
  rg_create
  create_ssh_keys
  load_ssh_keys
  cluster_deploy
  cluster_logs
  aks_get_credentials
  get_deployment_info
  scp_to_jumpbox "${KUBECONFIG}"
  do_install_druid
  afterboot
}

# removes the Azure resources and Druid
do_delete() {
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
  install)        do_install ;;
  delete)         do_delete ;;
  install-druid)  do_install_druid ;;
  delete-druid)   do_delete_druid ;;
  dry-run)        do_dry_run ;;
  *)              usage ;;
  esac
  unset _opt
}

config_case() {
  local _opt=$1

  case ${_opt} in
  KeepSSHKeys)    PURGE=0 ;; # dont remove the SSH Keys
  *)              usage ;;
  esac
  unset _opt
}

main() {
  while getopts "o:x:" opt; do
    case $opt in
    o)
      opt_flag=true
      OPTIONS="${OPTARG}"
      ;;
    x)
      exec_flag=true
      EXEC_OPT="${OPTARG}"
      ;;

    *) usage ;;
    esac
  done
  shift $(($OPTIND - 1))

  if [ $OPTIND = 1 ]; then
    usage
    exit 0
  fi

  # process options
  if [[ "${opt_flag}" == "true" ]]; then
    config_case "${OPTIONS}"
  fi

  # process actions
  if [[ "${exec_flag}" == "true" ]]; then
    # check if we are logged first
    check_for_azure_login
    exec_case "${EXEC_OPT}"
  fi 
}

main "$@"

exit 0
