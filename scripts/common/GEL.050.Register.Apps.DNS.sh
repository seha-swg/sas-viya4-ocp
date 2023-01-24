#!/bin/bash
###############################################################################
#        Name: GEL.050.Register.Apps.DNS.sh                                   #
# Description: Register Apps DNS                                              #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-azure-create-ingress-dns-records_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,    Initial release,                                  OCT-2021 #
# Edoardo Riva,    Split out DNS regisitration from previous script  APR 2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
export KUBECONFIG=${CLUSTERCONF_DIR}/auth/kubeconfig

CLUSTER_FQDN="${CLUSTER_NAME}.${BASE_DOMAIN}"

#the default route should be exposed with a public IP.
registerIngressDNS () {
    APPS_IP=$(oc --kubeconfig ${KUBECONFIG} -n openshift-ingress get service router-default -o json | jq -r .status.loadBalancer.ingress[0].ip)
    if [[ -n "${APPS_IP}"  && "${APPS_IP}" != "null" ]]; then
        add_update_VARS_FILE APPS_IP
        logit "registering public apps IP ${APPS_IP} on local hosts file"
        # update local hosts file
        ansible all -m lineinfile -b \
            -a "path=/etc/hosts \
            line=\"${APPS_IP} console-openshift-console.apps.${CLUSTER_FQDN} apps.${CLUSTER_FQDN}\" \
            state=present" \
            --diff

        # Add IP to GEL DNS when we are in GELenable
        if [[ ${BASE_DOMAIN} == gelenable.sas.com ]]; then
            logit "registering public apps IP ${APPS_IP} in GEL DNS"
            PublicIPName=$(az network public-ip list -g ${AZURE_INFRA_RG} -o table | grep ${APPS_IP} | cut -f1 -d' ')
            PublicIPID=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${PublicIPName} --query "id" -o tsv)
            az network dns record-set a create -g gel_dns --subscription ${AZURE_GEL_SUBSCRIPTION_ID} -z ${BASE_DOMAIN} -n "*.apps.${CLUSTER_NAME}" --target-resource "${PublicIPID}"
        fi
    fi
}

validateIngressDNS () {
    # hostname resolution failed gives RC=6
    # connection refused gives RC=28; invalid certificate RC=60
    # A succesfull call should answer "Hello OpenShift!".
    # Wait up to 2 minutes for DNS propagation to work
    validate -t 120 -s 15 -c "curl -sk -m 10 https://canary-openshift-ingress-canary.apps.${CLUSTER_FQDN}"
}

deleteIngressDNS () {
    # delete the public loadbalancer ip addresses
    APPS_IP=$(oc --kubeconfig ${KUBECONFIG} -n openshift-ingress get service router-default -o json | jq -r .status.loadBalancer.ingress[0].ip)
    if [[ -n "${APPS_IP}"  && "${APPS_IP}" != "null" ]]; then
        logit "removing DNS registration of apps IP ${APPS_IP} from local hosts file"
        # update local hosts file
        ansible all -m lineinfile -b \
            -a "path=/etc/hosts \
            regex=\"${APPS_IP}\" \
            state=absent" \
            --diff

        # Delete IP from GEL DNS when we are in GELenable
        if [[ ${BASE_DOMAIN} == gelenable.sas.com ]]; then
            logit "removing public apps IP ${APPS_IP} from GEL DNS"
            az network dns record-set a delete -g gel_dns --subscription ${AZURE_GEL_SUBSCRIPTION_ID} -z ${BASE_DOMAIN} -n "*.apps.${CLUSTER_NAME}" --yes
        fi
    fi
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            registerIngressDNS
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteIngressDNS
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateIngressDNS
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac