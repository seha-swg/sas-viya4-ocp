#!/bin/bash
###############################################################################
#        Name: GEL.044.Post.OCP.Bootstrap                                     #
# Description: Wait for the control plane to ready, then delete               #
#              bootstrap resources                                            #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-azure-user-infra-wait-for-bootstrap_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig

waitForCluster () {
    logit "Waiting until OCP bootstrap is finished - up to 20 minutes"
    # give it 2 minutes, just in case
    sleep 2m
    openshift-install wait-for bootstrap-complete --dir=${CLUSTERCONF_DIR} \
    --log-level info
    [ $? -ne 0 ] && notifyandabort "ERROR: Openshift bootstrap may have failed or it may be impossible to connect to it" && return ${_ABORT_CODE}
    logit "Done waiting. OCP bootstrap should be finished"
}

deleteBootstrap () {
    logit "Deleting OCP bootstrap artifacts"
    DELETESCRIPT=$(find "$(dirname $0)" -iname *create*ocp*bootstrap* -xtype f)
    bash ${DELETESCRIPT} clean
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            waitForCluster
            # abort only if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && exit ${_ABORT_CODE}
            deleteBootstrap
        fi
    ;;
    'stop')
    ;;
    'clean')
    ;;
    'update')
    ;;
    'validate')
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac