#!/bin/bash
###############################################################################
#        Name: GEL.032.Azure.PreCluster.sh                                    #
# Description: Create Azure artifacts preliminary to creating cluster         #
# See: https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-azure-create-resource-group-and-identity_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
# Edoardo Riva,        get tags from gellow                          APR-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

createGroupAndIdentity () {
    logit "creating resource group ${AZURE_INFRA_RG} and managed identity ${AZURE_INFRA_RG}"
    # Get tags from the file created by GELLOW gel_tags function
    # tags should be with no quotes, space-separated in the form: key=value key2=value2 key3=value3
    AZ_TAGS=$(cat /home/cloud-user/MY_TAGS.txt | tr -d ' "' | tr ',' ' ')
    # Add Project tag
    AZ_TAGS="${AZ_TAGS} gel_project=${GELENABLE_WORKSHOP_CODE}"
    # This is the group that will host the HW for OCP
    az group create --name ${AZURE_INFRA_RG} --location ${AZURE_REGION} --tags $AZ_TAGS
    # Create a managed identity with permissions limited to the group
    az identity create -g ${AZURE_INFRA_RG} -n ${AZURE_INFRA_RG}-identity
    PRINCIPAL_ID=$(az identity show -g ${AZURE_INFRA_RG} -n ${AZURE_INFRA_RG}-identity --query principalId --out tsv)
    AZURE_INFRA_RG_ID=$(az group show -g ${AZURE_INFRA_RG} --query id --out tsv)

    set +e
    logit "Wait up to 60 seconds for AD propagation to get Service Principal ID"
    for i in 1 2 3 4 5 6
    do
        echo "Wait $i times"
        sleep 10
        az ad sp show --id $PRINCIPAL_ID
        if [ $? -eq 0 ]; then break; fi
        done
    set -e

    az role assignment create --assignee "${PRINCIPAL_ID}" --role 'Contributor' --scope "${AZURE_INFRA_RG_ID}"
    #is UAA role required? It's not in the doc, but was in the example I followed.
    az role assignment create --assignee "${PRINCIPAL_ID}" --role 'User Access Administrator' --scope "${AZURE_INFRA_RG_ID}"
}

validatePreCluster () {
    validate -t 60s -s 5 -c "az group show --name ${AZURE_INFRA_RG}"
    if [ $? -ne 0 ]; then
        notifyandabort "ERROR: Failure creating Azure group ${AZURE_INFRA_RG}"
        return ${_ABORT_CODE}
    fi

    validate -t 60s -s 5 -c "az ad sp show --id $PRINCIPAL_ID"
    if [ $? -ne 0 ]; then
        notifyandabort "ERROR: Failure creating Azure Service Principal ${PRINCIPAL_ID}"
        return ${_ABORT_CODE}
    fi

}

deleteGroup () {
    logit "Going to delete main cluster resorce group"
    logit "this is irreversible and will destroy every resource inside it"
    logit "it may take a few minutes"
    az group delete -y --name ${AZURE_INFRA_RG} --no-wait
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createGroupAndIdentity
            validatePreCluster
            # abort only if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && exit ${_ABORT_CODE}
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteGroup
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validatePreCluster
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac