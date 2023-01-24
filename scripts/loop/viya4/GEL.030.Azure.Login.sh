#!/bin/bash
###############################################################################
#        Name: GEL.030.Azure.Login.sh                                         #
# Description: Login to Azure with the course service principal               #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

azLogin () {
    #Get Azure credential
    AZ_PASSWD=$(curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/PSGEL300_Secret.txt)
    az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZ_PASSWD} --tenant ${AZURE_TENANT_ID}
    az configure --defaults location=${AZURE_REGION}
}

azLogout () {
    az logout
}

validateLogin () {
    az account show
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            logit "Logging into Azure"
            azLogin
            validateLogin
        fi
    ;;
    'stop')
        if isFirstHost ; then
            logit "Logout from Azure"
            azLogout
        fi
    ;;
    'clean')
        if isFirstHost ; then
            azLogout
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateLogin
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac