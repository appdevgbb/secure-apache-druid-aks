#!/usr/bin/env bash

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

druid_ns() {
  # Create a Namespace for Druid
  cmd kubectl $1 ns druid

  # Setup Service Account
  cmd kubectl $1 -f deploy/service_account.yaml

  # Setup RBAC
  cmd kubectl $1 -f deploy/role.yaml
  cmd kubectl $1 -f deploy/role_binding.yaml
}

druid_crd() {
  # Setup the CRD
  cmd kubectl $1 -f deploy/crds/druid.apache.org_druids.yaml
}

druid_operator() {
  # Deploy the druid-operator
  cmd kubectl $1 -f deploy/operator.yaml

  if [[ $1 == 'create' ]]; then
    # Check the deployed druid-operator
    cmd kubectl describe deployment druid-operator
  fi
}

druid_cluster() {
  # Deploy a sample druid cluster
  cmd kubectl $1 -f  examples/tiny-cluster-zk.yaml

  # hack: for the tiny cluster to work I had to change the fsGroup,runAsUser and runAsGroup to 0. 
  cmd kubectl $1 -f  examples/tiny-cluster.yaml
}

druid_addons() {
  # druid-exporter
  local DRUID_EXPORTER_GH=https://raw.githubusercontent.com/opstree/druid-exporter/master
  cmd kubectl $1 -f $DRUID_EXPORTER_GH/manifests/deployment.yaml -n druid
  cmd kubectl $1 -f $DRUID_EXPORTER_GH/manifests/service.yaml -n druid

  echo "Open Grafana and add the following dashboard: 12155"
  echo "https://grafana.com/grafana/dashboards/12155"
}

do_install() {
  druid_ns create
  druid_crd create
  druid_operator create
  druid_cluster create
}

do_delete() {
 druid_cluster delete
 druid_operator delete
 druid_crd delete
 druid_ns delete 
}

exec_case() {
    local _opt=$1

    case ${_opt} in
    install)    do_install;;
    delete)     do_delete;;
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
