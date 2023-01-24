#!/bin/bash
###############################################################################
#        Name: GEL.054.Grant.Access.To.ACR                                    #
# Description: Grant access to the shared GEL registry gelregistry.azurecr.io #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              NOV-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# location where OCP manifests reside
ACR_NAME=gelregistry
ACR_GROUP=gel-common-rg
SERVICE_PRINCIPAL_ID=${AZURE_CLIENT_ID}
##Maybe the SP should be the OCP managed identity?

grantPullPermission () {
    logit "Granting pull permissions to managed identity"
    # Get the ID of the GEL registry
    ACR_REGISTRY_ID=$(az acr show --name ${ACR_NAME} -g ${ACR_GROUP} --query id --output tsv)
    # Assign the desired role to the service principal. Modify the '--role' argument
    # value as desired:
    # acrpull:     pull only
    # acrpush:     push and pull
    # owner:       push, pull, and assign roles
    az role assignment create --assignee ${SERVICE_PRINCIPAL_ID} --scope ${ACR_REGISTRY_ID} --role acrpull
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            grantPullPermission
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