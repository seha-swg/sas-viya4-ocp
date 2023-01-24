#!/bin/bash
###############################################################################
#        Name: GEL.200.AutoDeploy.Viyash                                      #
# Description: Autodeploy Viya when requested                                 #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release                               MAY-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

IsAutoDeployRequested () {
    IsRequested=1
    # Use workshop comment to decide
    if [[ $race_coll_comment == *"DEPLOY_"* ]]; then
        logit "auto-deploying SAS Viya since collection comment includes DEPLOY_"
        IsRequested=0
    fi
    return ${IsRequested}
}

AutoDeploy () {
    #exec the _all.sh cheatcode file if it exists
    if [[ -f /home/cloud-user/${GIT_WKSHP_PROJECT}/_all.sh ]]; then
        logit "Going to automatically run all exercises, including the autodeploy of SAS Viya"
        sudo -u cloud-user -E bash /home/cloud-user/${GIT_WKSHP_PROJECT}/_all.sh
        logit "Viya deployment launched, it may take up to 1 hour for it to be available"
        logit "Monitor with 'gel_ReadyViya4 -n gel-viya -r 50 -s 10'"
    else
        logit "_all.sh cheatcode script not found. Unable to autodeploy."
    fi
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            if IsAutoDeployRequested; then
                AutoDeploy
            fi
        fi
    ;;
    'stop')
    ;;
    'clean')
        logit "Automatic workshop Cleanup is not implemented yet"
    ;;
    'update')
    ;;
    'validate')
    ;;
    'list')
    ;;
    'autodeploy')
        if isFirstHost ; then
            AutoDeploy
        fi
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac