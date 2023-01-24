#!/bin/bash
###############################################################################
#        Name: GEL.010.Define.Environment.sh                                  #
# Description: Ensure azure variables are set for the workshop                #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
# Edoardo Riva,        Switch to gelenable                           MAR-2022 #
# Edoardo Riva,        VM IMage moved to shared resource group       AUG-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

function getAZCredentials() {
    logit "Obtain credentials"
    mkdir -p ${WORK_DIR}/vars/GELENABLE_CREDS
    curl -sk https://gelweb.race.sas.com/scripts/gelenable/security/${GELENABLE_WORKSHOP_CODE}_sp_cert.pem > ${WORK_DIR}/vars/GELENABLE_CREDS/SP_cert.pem
    curl -sk https://gelweb.race.sas.com/scripts/gelenable/security/${GELENABLE_WORKSHOP_CODE}_sp_cert.pfx > ${WORK_DIR}/vars/GELENABLE_CREDS/SP_cert.pfx
    mySP_Id=$(curl -sk https://gelweb.race.sas.com/scripts/gelenable/security/${GELENABLE_WORKSHOP_CODE}_sp_id.txt)
    myTenant_Id=$(curl -sk https://gelweb.race.sas.com/scripts/gelenable/security/tenantID.txt)
    if [[ -z ${mySP_Id} ]] ; then
        logit "ERROR: Failed to obtain Workshop Service Principal ID. Using hard-coded value"
        # this is PSGEL300 Service Principal ID
        AZURE_CLIENT_ID=668399fd-8533-4915-bc82-9f4fda424aa8
    else
        AZURE_CLIENT_ID=${mySP_Id}
    fi
    if [[ -z ${myTenant_Id} ]] ; then
        logit "ERROR: Failed to obtain GELENABLE Tenant ID. Using hard-coded value"
        # this is GELEnable tenant
        AZURE_TENANT_ID=a708fb09-1d96-416a-ad34-72fa07ff196d
    else
        AZURE_TENANT_ID=${myTenant_Id}
    fi
    if ! [[ -f ${WORK_DIR}/vars/GELENABLE_CREDS/SP_cert.pem ]] ; then
        notifyandabort "ERROR: Failed to obtain Workshop Service Principal Certificate"
        #if we do not get this, nothing in the workshop will work
        return ${_ABORT_CODE}
    fi

    #write variables to vars file
    add_update_VARS_FILE AZURE_TENANT_ID
    add_update_VARS_FILE AZURE_CLIENT_ID

}

function removeAZCredentials () {
    [[ -d ${WORK_DIR}/vars/GELENABLE_CREDS ]] && rm -rf ${WORK_DIR}/vars/GELENABLE_CREDS
}

function setAZVariables () {

    # Fetch Workshop Subscription ID
    AZURE_SUBSCRIPTION_ID=$(echo ${myResult}|jq -r --arg test1 "${GELENABLE_WORKSHOP_CODE}" '.[] | select(.name | contains($test1)) | .id')
    logit "Workshop Subscription ID: ${AZURE_SUBSCRIPTION_ID}"
    # this shold be "PSGEL300 SAS Viya Deploy Red Hat OpenShift"
    #AZURE_SUBSCRIPTION_ID=c1eea1ae-7109-4c52-a776-3b75dfb5b684

    # Set the Azure subscription
    #az account list
    az account set -s "${AZURE_SUBSCRIPTION_ID}"

    # Fetch Persistent Subscription ID (for DNS, VM image, etc)
    AZURE_GEL_SUBSCRIPTION_ID=$(echo ${myResult}|jq -r --arg test1 "GEL Persistent Resources" '.[] | select(.name | contains($test1)) | .id')
    # this should be "GEL Persistent Resources"
    #AZURE_GEL_SUBSCRIPTION_ID=5483d6c1-65f0-400d-9910-a7a448614167

    # image ID for the OCP RHCOS image
    # used to be in:
    #/subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/resourceGroups/PSGEL300/providers/Microsoft.Compute/galleries/GEL/images/
    # now is in:
    #/subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/resourceGroups/GEL_COMPUTE_GALLERY/providers/Microsoft.Compute/galleries/GEL_Compute_Gallery/images/
    IMAGE_ID="/subscriptions/${AZURE_GEL_SUBSCRIPTION_ID}/resourceGroups/GEL_COMPUTE_GALLERY/providers/Microsoft.Compute/galleries/GEL_Compute_Gallery/images/${OCP_IMAGE_NAME}"

    # select a region with enough capacity
    # see https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-account.html#installation-azure-limits_installing-azure-account
    AZURE_REGION=eastus2

    # Resource Group for Azure Cluster
    AZURE_INFRA_RG=$(cat /home/cloud-user/MY_PREFIX.txt)

    # Storage account name: "Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only".
    # On RACE machines such as rext03-0269 we have to remove the dash. Also, let's make sure it's lower-case.
    AZURE_SA_NAME=${CLUSTER_NAME//-/}sa;AZURE_SA_NAME=${AZURE_SA_NAME,,}

    # OCP Base Domain
    BASE_DOMAIN=gelenable.sas.com

    #write variables to vars file
    add_update_VARS_FILE AZURE_SUBSCRIPTION_ID
    add_update_VARS_FILE AZURE_GEL_SUBSCRIPTION_ID
    add_update_VARS_FILE AZURE_REGION
    add_update_VARS_FILE AZURE_INFRA_RG
    add_update_VARS_FILE AZURE_SA_NAME
    add_update_VARS_FILE BASE_DOMAIN
    add_update_VARS_FILE IMAGE_ID

    az configure --defaults location=${AZURE_REGION}
}

azLogin () {
    logit "Authenticate using Azure CLI"
    myResult=$(az login --service-principal -u ${AZURE_CLIENT_ID} -p ${WORK_DIR}/vars/GELENABLE_CREDS/SP_cert.pem -t ${AZURE_TENANT_ID})
    if [[ -z ${myResult} ]] ; then
        notifyandabort "ERROR: Something went wrong authenticating the Workshop Service Principal ${AZURE_CLIENT_ID} in Azure"
        return ${_ABORT_CODE}
    fi
}

azLogout () {
    az logout
}

validateLogin () {
    az account show
}

setUserDefaults () {
    # Add the region as the default for cloud-user
    ansible localhost -m lineinfile \
    -a "dest=/home/cloud-user/.bashrc \
        regexp='^export AZUREREGION' \
        line='export AZUREREGION=$AZURE_REGION'" \
        -b --become-user cloud-user \
        --diff


    # Add the resource group as the default for cloud-user
    ansible localhost -m lineinfile \
    -a "dest=/home/cloud-user/.bashrc \
        regexp='^export AZURE_RG' \
        line='export AZURE_RG=${AZURE_INFRA_RG}'" \
        -b --become-user cloud-user \
        --diff

    # set Azure defaults
    ansible localhost -m lineinfile \
    -a "dest=/home/cloud-user/.bashrc \
        regexp='^az configure' \
        line='az configure --defaults location=${AZURE_REGION} group=${AZURE_INFRA_RG}'" \
        -b --become-user cloud-user \
        --diff
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost; then
            getAZCredentials
            # abort the script if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && exit ${_ABORT_CODE}
            azLogin
            # abort the script if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && exit ${_ABORT_CODE}
            setAZVariables
            setUserDefaults
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            logit "Logout from Azure and remove credentials"
            azLogout
            removeAZCredentials
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
