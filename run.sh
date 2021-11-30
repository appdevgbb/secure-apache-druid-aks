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
    "$@"
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

# install the Azure resources and Druid
do_install() {
    rg_create
    create_ssh_keys
    load_ssh_keys
    cluster_deploy
    aks_get_credentials
    do_install_druid
}

# removes the Azure resources and Druid
do_delete() {
  do_delete_druid
  do_delete_azure_resources
}

exec_case() {
    local _opt=$1

    case ${_opt} in
    install)          do_install;;
    delete)           do_delete;;
    install-druid)    do_install_druid;;
    delete-druid)     do_delete_druid;;
    dry-run)          cluster_dry_run;;
    *)          usage;;
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
