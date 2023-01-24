#!/bin/bash
###############################################################################
#        Name: GEL.010.Define.Environment.sh                                  #
# Description: Ensure azure variables are set for the workshop                #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
# Edoardo Riva,        Switch to gelenable                           MAR-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# this is sas-gelsandbox
AZURE_SUBSCRIPTION_ID=c973059c-87f4-4d89-8724-a0da5fe4ad5c
# this is SAS tenant
AZURE_TENANT_ID=b1c14d5c-3625-45b3-a430-9552373a0c2f
# this is PSGEL300 Service Principal ID
AZURE_CLIENT_ID=37f11bee-ecae-462c-850c-e8d2bf09a199
# this is the shared GEL subscription
AZURE_GEL_SUBSCRIPTION_ID=b91ae007-b39e-488f-bbbf-bc504d0a8917

#image ID for the OCP RHCOS image
#/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Compute/galleries/GEL/images/PSGEL300-OCP-47
IMAGE_ID="/subscriptions/${AZURE_GEL_SUBSCRIPTION_ID}/resourceGroups/${GIT_WKSHP_CODE}/providers/Microsoft.Compute/galleries/GEL/images/${OCP_IMAGE_NAME}"

# select a region with enough capacity
# see https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-account.html#installation-azure-limits_installing-azure-account
AZURE_REGION=eastus2
# Resource Group for Azure Cluster
AZURE_INFRA_RG="${GIT_WKSHP_CODE}-${short_race_hostname}"

# Storage account name: "Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only".
# On RACE machines such as rext03-0269 we have to remove the dash. Also, let's make sure it's lower-case.
AZURE_SA_NAME=${CLUSTER_NAME//-/}sa;AZURE_SA_NAME=${AZURE_SA_NAME,,}

# OCP Base Domain
BASE_DOMAIN=gelsandbox.race.sas.com

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost && [[ "${GIT_WKSHP_CODE}" == "PSGEL300" ]] ; then

            add_update_VARS_FILE AZURE_SUBSCRIPTION_ID
            add_update_VARS_FILE AZURE_TENANT_ID
            add_update_VARS_FILE AZURE_CLIENT_ID
            add_update_VARS_FILE AZURE_REGION
            add_update_VARS_FILE AZURE_INFRA_RG
            add_update_VARS_FILE AZURE_SA_NAME
            add_update_VARS_FILE BASE_DOMAIN
            add_update_VARS_FILE IMAGE_ID
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
