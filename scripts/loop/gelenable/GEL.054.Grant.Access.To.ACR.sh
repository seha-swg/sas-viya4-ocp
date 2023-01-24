#!/bin/bash
###############################################################################
#        Name: GEL.054.Grant.Access.To.ACR                                    #
# Description: Grant access to the shared GEL registry                        #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release, for GELenable tenant         APR-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# location where OCP manifests reside
ACR_NAME=gelcontainerregistry
ACR_GROUP=GEL_ContainerRegistry
SERVICE_PRINCIPAL_ID=${AZURE_CLIENT_ID}
##Maybe the SP should be the OCP managed identity?

grantPullPermission () {
    logit "Granting pull permissions to managed identity"
    # Get the ID of the GEL registry
    ACR_REGISTRY_ID=$(az acr show --name ${ACR_NAME} -g ${ACR_GROUP} --subscription ${AZURE_GEL_SUBSCRIPTION_ID} --query id --output tsv)
    # Assign the desired role to the service principal. Modify the '--role' argument
    # value as desired:
    # acrpull:     pull only
    # acrpush:     push and pull
    # owner:       push, pull, and assign roles
    ## the "read" role is already assigned to the PSGEL300_sp principal
    # az role assignment create --assignee ${SERVICE_PRINCIPAL_ID} --scope ${ACR_REGISTRY_ID} --role acrpull
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