#!/bin/bash
###############################################################################
#        Name: GEL.036.Create.Azure.LoadBalancer                              #
# Description: Create the infrastructure required to deploy OCP               #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-arm-dns_installing-azure-user-infra #
#     Initially I only created the internal LB to keep the cluster private    #
#     but these scripts are running in RACE (totally different net) so we     #
#     so we also need a public LB to reach the cluster from here.             #
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
BASE_NAME=${AZURE_INFRA_RG}

CLUSTER_FQDN="${CLUSTER_NAME}.${BASE_DOMAIN}"

createLB () {
    logit "creating Azure Loadbalancer(s) in group ${AZURE_INFRA_RG}"
    # This template creates:
    #   1 public static IP
    #   1 internal and 1 public loadbalancers
    #   2 A records in the private DNS that point to the internal frontend IP
    az deployment group create -g ${AZURE_INFRA_RG} \
       --template-file "${ARM}/02_loadbalancer.json" \
       --parameters baseName="${BASE_NAME}" \
       --parameters privateDNSZoneName="${CLUSTER_NAME}.${BASE_DOMAIN}"
}

validateLB () {
    validate -t 60s -s 5 -c "az network lb show --resource-group ${AZURE_INFRA_RG} --name ${BASE_NAME}-internal-lb -o table"
    validate -t 60s -s 5 -c "az network lb show --resource-group ${AZURE_INFRA_RG} --name ${BASE_NAME}-public-lb -o table"
}

registerDNS () {
    # register the public loadbalancer ip addresses

    API_IP=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${BASE_NAME,,}-public-lb-pip-1 --query ipAddress -o tsv)
    if [[ -n "${API_IP}" ]]; then
        add_update_VARS_FILE API_IP
        logit "registering public Loadbalancer IP ${API_IP} on local hosts file"
        # update local hosts file
        ansible all -m lineinfile -b \
            -a "path=/etc/hosts \
            line=\"${API_IP}  api.${CLUSTER_FQDN}\" \
            state=present" \
            --diff

        # Add IP to GEL DNS when we are in GELenable
        if [[ ${BASE_DOMAIN} == gelenable.sas.com ]]; then
            logit "registering public Loadbalancer IP ${API_IP} in GEL DNS"
            PublicIPID=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${BASE_NAME,,}-public-lb-pip-1 --query "id" -o tsv)
            az network dns record-set a create -g gel_dns --subscription ${AZURE_GEL_SUBSCRIPTION_ID} -z ${BASE_DOMAIN} -n "api.${CLUSTER_NAME}" --target-resource "${PublicIPID}"
        fi
    fi

#   APPS_IP=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${BASE_NAME,,}-public-lb-pip-2 --query ipAddress -o tsv)
#   if [[ -n "${APPS_IP}" ]]; then
#       add_update_VARS_FILE APPS_IP
#       logit "registering in DNS public Loadbalancer IP ${APPS_IP}"
#       # update local hosts file
#       ansible all -m lineinfile -b \
#           -a "path=/etc/hosts \
#           line=\"${APPS_IP} console-openshift-console.apps.${CLUSTER_FQDN} apps.${CLUSTER_FQDN} ${CLUSTER_FQDN}\" \
#           state=present" \
#           --diff
#   fi
}

deleteDNS () {
    # delete the public loadbalancer ip addresses

    API_IP=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${BASE_NAME,,}-public-lb-pip-1 --query ipAddress -o tsv)
    if [[ -n "${API_IP}" ]]; then
        logit "removing registration of Loadbalancer IP ${API_IP} from local hosts file"
        # update local hosts file
        ansible all -m lineinfile -b \
            -a "path=/etc/hosts \
            regex=\"${API_IP}\" \
            state=absent" \
            --diff

        # Delete IP from GEL DNS when we are in GELenable
        if [[ ${BASE_DOMAIN} == gelenable.sas.com ]]; then
            logit "removing public Loadbalancer IP ${API_IP} from GEL DNS"
            az network dns record-set a delete -g gel_dns --subscription ${AZURE_GEL_SUBSCRIPTION_ID} -z ${BASE_DOMAIN} -n "api.${CLUSTER_NAME}" --yes
        fi

    fi

#   APPS_IP=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${BASE_NAME,,}-public-lb-pip-2 --query ipAddress -o tsv)
#   if [[ -n "${APPS_IP}" ]]; then
#       add_update_VARS_FILE APPS_IP
#       logit "removing DNS registration of Loadbalancer IP ${APPS_IP}"
#       # update local hosts file
#       ansible all -m lineinfile -b \
#           -a "path=/etc/hosts \
#           regex=\"${APPS_IP}\" \
#           state=absent" \
#           --diff
#   fi
}

validateDNS () {
    # hostname resolution failed gives RC=6
    # connection refused gives RC=28
    # we like 28, it means it can resolve the hostname.
    validate -t 30 -s 10 -c "curl -s -m 2 https://api.${CLUSTER_FQDN}; [ $? != 6 ]"
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createLB
            validateLB
            registerDNS
            validateDNS
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteDNS
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateLB
            validateDNS
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac