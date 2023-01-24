#!/bin/bash
###############################################################################
#        Name: GEL.020.Define.Viya.Parameters.sh                              #
# Description: Define Viya deployment parameters for the workshop             #
# See https://gitlab.sas.com/GEL/workshops/PSGEL260-sas-viya-4.0.1-administration/-/blob/main/scripts/loop/core/GEL.0100.Set.Deployment.Parameter.sh #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release                               MAY-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

setDeploymentParameters () {
    versionFile=/home/cloud-user/${GIT_WKSHP_PROJECT}/README.md
    GELLOW_NAMESPACE=gel-viya

    #the markdown file should have a comment such as:
    #```yaml
    #Cadence : stable
    #Version : 2021.2.6
    #```
    cadence_from_project=$(grep Cadence ${versionFile} | cut -d':' -f2 | tr  -d ' ')
    version_from_project=$(grep Version ${versionFile} | cut -d':' -f2 | tr  -d ' ')

    GELLOW_CADENCE_NAME="${cadence_from_project}"
    GELLOW_CADENCE_VERSION="${version_from_project}"
    GELLOW_CADENCE_RELEASE="latest"
    GELLOW_ORDERNICKNAME="simple"

    add_update_VARS_FILE GELLOW_NAMESPACE
    add_update_VARS_FILE GELLOW_CADENCE_NAME
    add_update_VARS_FILE GELLOW_CADENCE_VERSION
    add_update_VARS_FILE GELLOW_CADENCE_RELEASE
    add_update_VARS_FILE GELLOW_ORDERNICKNAME

    logit "   Viya Deployment:"
    logit "      Namespace: ${GELLOW_NAMESPACE}"
    logit "      Cadence: ${GELLOW_CADENCE_NAME}"
    logit "      Version: ${GELLOW_CADENCE_VERSION}"
    logit "      Release: ${GELLOW_CADENCE_RELEASE}"
    logit "      Order: ${GELLOW_ORDERNICKNAME}"

}


case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost; then
            logit "Setting Workshop Deployment Parameters"
            setDeploymentParameters
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
