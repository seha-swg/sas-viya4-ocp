#!/bin/bash
###############################################################################
#        Name: GEL.052.Configure.OCP.Auth                                     #
# Description: Configure an LDAP Identity Provider for OCP                    #
# See https://docs.openshift.com/container-platform/4.9/authentication/identity_providers/configuring-ldap-identity-provider.html#configuring-ldap-identity-provider #
# See https://gitlab.sas.com/GEL/utilities/gellow/-/blob/validation/doc/GELENABLE_Azure_AD.md #
# See https://gitlab.sas.com/GEL/utilities/gellow/-/blob/validation/scripts/loop/gelenable/gelenable_site-config/gelenable-sitedefault.yaml #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release, for GELenable tenant         MAY-2022 #
# Edoardo Riva,        Add OCP Admin from LDAP                       AUG-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# GELEnable-specific values
ADDS_NSG="aadds-nsg"
ADDS_RG="GEL_AZADDS"
ADDS_SUB=${AZURE_GEL_SUBSCRIPTION_ID:-5483d6c1-65f0-400d-9910-a7a448614167}

# Connection details are stored in gellow. They are available at runtime in $CODE_DIR
LDAP_FILE=${CODE_DIR}/scripts/loop/gelenable/gelenable_site-config/gelenable-sitedefault.yaml

# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
export KUBECONFIG=${CLUSTERCONF_DIR}/auth/kubeconfig

# source of OCP templates
OCP_ASSETS_DIR="$(dirname $0)/../../../assets/OCP"

PROJECT_DIR=/home/cloud-user/project/clusterconfig/auth
CLUSTER_ADMIN_NAME="gatedemo003"

openLDAPPort () {
    # Code source: https://gitlab.sas.com/GEL/utilities/gellow/-/blob/main/scripts/loop/gelenable/GEL.0911.Optional.GELENABLE.IAC.sh#L284-310
    # Add Network Security Group NSG Rule to allow access to Azure Active Directory Domain Services
    # Required to allow access to the LDAPS interface
    logit "**** Add AADDS NSG ****"
    # OCP outbound connections go through the NAT gateway created in script GEL.034.Azure.Create.VNET
    PublicIPAdd=$(az network public-ip show -g ${AZURE_INFRA_RG} --name ${AZURE_INFRA_RG}-nat-pip --query "ipAddress" -o tsv)
    ADDS_Priority=$(az network nsg rule list --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB} -o tsv --query "[].priority"|sort|tail -1)
    ADDS_Priority=$((ADDS_Priority+1))
    myResult=$(az network nsg rule create --name ${AZURE_INFRA_RG}_to_ADDS --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB} --priority ${ADDS_Priority} \
        --access Allow --destination-address-prefixes "VirtualNetwork" --destination-port-ranges 636 --direction Inbound --protocol '*' \
        --source-address-prefixes ${PublicIPAdd} --source-port-ranges '*')
    retVal=$?
    if [ $retVal -ne 0 ]; then
        # Deal with multiple rules being added at the same time so the priority has clashed with another rule
        sleep 5
        ADDS_Priority=$(az network nsg rule list --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB} -o tsv --query "[].priority"|sort|tail -1)
        ADDS_Priority=$((ADDS_Priority+1))
        myResult=$(az network nsg rule create --name ${AZURE_INFRA_RG}_to_ADDS --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB} --priority ${ADDS_Priority} \
        --access Allow --destination-address-prefixes "VirtualNetwork" --destination-port-ranges 636 --direction Inbound --protocol '*' \
        --source-address-prefixes ${PublicIPAdd} --source-port-ranges '*')
    fi
    logit "**** NSG AADDS Added ****"
}

createAndLoadLDAPSecret () {
    LDAP_PASSWORD=$(yq4 eval '.config.application."sas.identities.providers.ldap.connection".password' ${LDAP_FILE})
    logit "     Creating ldap-secret in OCP openshift-config namespace"
    oc --kubeconfig ${KUBECONFIG} create secret generic ldap-secret --from-literal=bindPassword=${LDAP_PASSWORD} -n openshift-config
}

createAndLoadLDAPCR () {
    # load LDAP info from Gellow file
    LDAP_HOST=$(yq4 eval '.config.application."sas.identities.providers.ldap.connection".host' ${LDAP_FILE})
    LDAP_PORT=$(yq4 eval '.config.application."sas.identities.providers.ldap.connection".port' ${LDAP_FILE})
    LDAP_BASEDN=$(yq4 eval '.config.application."sas.identities.providers.ldap.user".baseDN' ${LDAP_FILE})
    LDAP_BINDDN=$(yq4 eval '.config.application."sas.identities.providers.ldap.connection".userDN' ${LDAP_FILE})
    LDAP_USER_ATTRIBUTE="sAMAccountName"
    # copy and customize CR definition file
    sed -e "s|{{ LDAP_HOST }}|${LDAP_HOST}|" \
        -e "s|{{ LDAP_PORT }}|${LDAP_PORT}|" \
        -e "s|{{ LDAP_BASEDN }}|${LDAP_BASEDN}|" \
        -e "s|{{ LDAP_BINDDN }}|${LDAP_BINDDN}|" \
        -e "s|{{ LDAP_USER_ATTRIBUTE }}|${LDAP_USER_ATTRIBUTE}|" \
        ${OCP_ASSETS_DIR}/ldap-cr.yaml \
        > ${PROJECT_DIR}/ldap-cr.yaml
    logit "     Creating ldap CR in OCP openshift-config namespace"
    oc --kubeconfig ${KUBECONFIG} apply -f ${PROJECT_DIR}/ldap-cr.yaml

}

defineOCPRoles () {
    ### Grant cluster admin rights to an LDAP user
    # OCP name maps to AAD {{ LDAP_USER_ATTRIBUTE }} // see ldap-cr.yaml
    oc --kubeconfig ${KUBECONFIG} \
        create clusterrolebinding \
        cluster-admin-psgel300 \
        --clusterrole=cluster-admin \
        --user="${CLUSTER_ADMIN_NAME}"
}

deleteLDAPCR () {
    # the following does not work:
    # Error from server (Forbidden): error when deleting "ldap-cr.yaml": oauths.config.openshift.io "cluster" is forbidden: deleting required oauths.config.openshift.io resource, named cluster, is not allowed
    #[[ -f ${PROJECT_DIR}/ldap-cr.yaml ]] && oc --kubeconfig ${KUBECONFIG} delete -f ${PROJECT_DIR}/ldap-cr.yaml

    # to do
    true
}

deleteLDAPSecret () {
    oc --kubeconfig ${KUBECONFIG} delete secret ldap-secret -n openshift-config
}

closeLDAPPort () {
    az network nsg rule delete --name ${AZURE_INFRA_RG}_to_ADDS --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB}
    logit "**** NSG AADDS Removed ****"
}

deleteOCPRoles () {
    oc --kubeconfig ${KUBECONFIG} delete clusterrolebinding cluster-admin-psgel300
}

validateLDAPPort () {
    validate -s 7 -t 22s -c "az network nsg rule show --name ${AZURE_INFRA_RG}_to_ADDS  --nsg-name ${ADDS_NSG} --resource-group ${ADDS_RG} --subscription ${ADDS_SUB}"
}

validateAuth () {
    validate -s 7 -t 22s -c "oc --kubeconfig ${KUBECONFIG} auth can-i create projects --as ${CLUSTER_ADMIN_NAME}"
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            openLDAPPort
            createAndLoadLDAPSecret
            createAndLoadLDAPCR
            defineOCPRoles
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteLDAPCR
            deleteLDAPSecret
            closeLDAPPort
            deleteOCPRoles
        fi
    ;;
    'update')
    ;;
    'validate')
        validateLDAPPort
        validateAuth
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac