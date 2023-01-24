#!/bin/bash
###############################################################################
#        Name: GEL.046.Create.OCP.workers VMs                                 #
# Description: Create the infrastructure required to deploy OCP               #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-creating-azure-worker_installing-azure-user-infra #
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
    export WORKER_IGNITION=$(cat ${CLUSTERCONF_DIR}/worker.ign | base64 | tr -d '\n')

    logit "creating OCP worker VMs in group ${AZURE_INFRA_RG}"
    az deployment group create -g ${AZURE_INFRA_RG} \
      --template-file "${ARM}/05_workers.json" \
      --parameters workerIgnition="${WORKER_IGNITION}" \
      --parameters sshKeyData="${SSH_KEY_CLUSTER}" \
      --parameters imageID="${IMAGE_ID}" \
      --parameters diagnosticStorageAccount="${AZURE_SA_NAME}" \
      --parameters numberOfNodes="${WORKER_REPLICAS}" \
      --parameters nodeVMSize="Standard_D8ds_v4"
    logit "Worker machines: \n$(az vm list --resource-group ${AZURE_INFRA_RG} --query "[?contains(name,'worker')].name" -o tsv)"
}

validateVM () {
    WORKERS_COUNT=$(az vm list --resource-group ${AZURE_INFRA_RG} --query "[?contains(name,'worker')].name" -o tsv | wc -l)
    if [ ${WORKER_REPLICAS} -ne ${WORKERS_COUNT} ]; then
        notifyandabort "ERROR: Expecting ${WORKER_REPLICAS} workers, found ${WORKERS_COUNT} instead. Aborting gellow."
        return ${_ABORT_CODE}
    fi
}

deleteVM () {
    logit "Deleting OCP workers VMs in group ${AZURE_INFRA_RG}"
    for VMNAME in $(az vm list --resource-group ${AZURE_INFRA_RG} --query "[?contains(name,'${AZURE_INFRA_RG}-worker')].name" -o tsv); do
        logit "Deleting ${VMNAME}"
        az vm stop -g ${AZURE_INFRA_RG} --name ${VMNAME}
        az vm deallocate -g ${AZURE_INFRA_RG} --name ${VMNAME}
        az vm delete -g ${AZURE_INFRA_RG} --name ${VMNAME} --yes
        az disk delete -g ${AZURE_INFRA_RG} --name ${VMNAME}_OSDisk --no-wait --yes
        az network nic delete -g ${AZURE_INFRA_RG} --name ${VMNAME}-nic
    done
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createVM
            validateVM
            # abort if the function aborted
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