#!/bin/bash
###############################################################################
#        Name: GEL.040.Create.OCP.Bootstrap VM                                #
# Description: Create the infrastructure required to deploy OCP               #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-creating-azure-bootstrap_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# load in the Azure machines cloud-user public key - although the userName there is 'core'
SSH_KEY_CLUSTER="$(cat /home/cloud-user/.ssh/cloud-user_id_rsa.pub)"
#location of ARM json templates
ARM="$(dirname $0)/../../../assets/azure"
# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig

createVM () {
    logit "Creating Azure storage account and uploading boostrap Ignition file"
    az storage account create -g ${AZURE_INFRA_RG} --location ${AZURE_REGION} --name ${AZURE_SA_NAME} --kind Storage --sku Standard_LRS
    ACCOUNT_KEY=$(az storage account keys list -g ${AZURE_INFRA_RG} --account-name ${AZURE_SA_NAME} --query "[0].value" -o tsv)
    az storage container create --name files --account-name ${AZURE_SA_NAME} --account-key ${ACCOUNT_KEY}
    az storage blob upload --account-name ${AZURE_SA_NAME} --account-key ${ACCOUNT_KEY} --name "bootstrap.ign" --container files --file "${CLUSTERCONF_DIR}/bootstrap.ign"

    # Get a read-only token valid for the next 30 minutes
    END_TIME=$(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ')
    BOOTSTRAP_URL=$(az storage blob generate-sas --name "bootstrap.ign" --container files --permissions r --expiry ${END_TIME} --full-uri --https-only --account-name ${AZURE_SA_NAME} --account-key ${ACCOUNT_KEY} -o tsv)
    BOOTSTRAP_IGNITION=$(jq -rcnM --arg v "3.2.0" --arg url ${BOOTSTRAP_URL} '{ignition:{version:$v,config:{replace:{source:$url}}}}' | base64 | tr -d '\n')

    logit "creating OCP Boostrap VM in group ${AZURE_INFRA_RG}"
    az deployment group create -g ${AZURE_INFRA_RG} \
      --template-file "${ARM}/03_bootstrap.json" \
      --parameters bootstrapIgnition="${BOOTSTRAP_IGNITION}" \
      --parameters sshKeyData="${SSH_KEY_CLUSTER}" \
      --parameters baseName="${AZURE_INFRA_RG}" \
      --parameters imageID="${IMAGE_ID}" \
      --parameters diagnosticStorageAccount="${AZURE_SA_NAME}"
}

validateVM () {
    validate -t 60s -s 5 -c "az vm show --resource-group ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap -o table"
    if [ $? -ne 0 ]; then
        notifyandabort "ERROR: Failure creating OCP Boostrap VM in group ${AZURE_INFRA_RG}"
        return ${_ABORT_CODE}
    fi
}

deleteVM () {
    logit "Deleting OCP bootstrap VM in group ${AZURE_INFRA_RG}"
    az vm stop -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap
    az vm deallocate -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap
    az vm delete -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap --yes
    az network nsg rule delete -g ${AZURE_INFRA_RG} --nsg-name ${AZURE_INFRA_RG}-nsg --name bootstrap_ssh_in
    az disk delete -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap_OSDisk --no-wait --yes
    az network nic delete -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-bootstrap-nic
    ACCOUNT_KEY=$(az storage account keys list -g ${AZURE_INFRA_RG} --account-name ${AZURE_SA_NAME} --query "[0].value" -o tsv)
    # also remove bootstrap file from blob container
    az storage blob delete --account-key ${ACCOUNT_KEY} --account-name ${AZURE_SA_NAME} --container-name files --name bootstrap.ign
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createVM
            validateVM
            # abort the script if the validation function aborted
            [[ $? == ${_ABORT_CODE} ]] && exit ${_ABORT_CODE}
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteVM
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateVM
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac