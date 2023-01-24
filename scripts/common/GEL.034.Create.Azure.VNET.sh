#!/bin/bash
###############################################################################
#        Name: GEL.034.Azure.Create.VNET                                      #
# Description: Create the infrastructure required to deploy OCP               #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

#location of ARM json templates
ARM="$(dirname $0)/../../../assets/azure"

createVNET () {
    logit "creating VNET with subnets, NSG, DNS, route-table in group ${AZURE_INFRA_RG}"
    az deployment group create -g ${AZURE_INFRA_RG} --template-file "${ARM}/01_vnet.json" --parameters baseName="${AZURE_INFRA_RG}"
    VNETID=$(az network vnet show --resource-group ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-vnet --query id --out tsv)
    az network private-dns zone create -g ${AZURE_INFRA_RG} -n ${CLUSTER_NAME}.${BASE_DOMAIN}
    az network private-dns link vnet create -g ${AZURE_INFRA_RG} -n ${AZURE_INFRA_RG}-vnet-PrivateDNSLink -z ${CLUSTER_NAME}.${BASE_DOMAIN} -v ${VNETID} -e true
    az network route-table create --name ${AZURE_INFRA_RG}-node-routetable -g ${AZURE_INFRA_RG}
}

validateVNET () {
    validate -t 60s -s 5 -c "az network vnet show --resource-group ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-vnet -o table"
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createVNET
            validateVNET
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            # do nothing
            return
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateVNET
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac