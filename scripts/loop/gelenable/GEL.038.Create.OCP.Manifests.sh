#!/bin/bash
###############################################################################
#        Name: GEL.034.Create.OCP.Manifests                                   #
# Description: Create the OCP manifests required for OCP installation         #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-user-infra-generate-k8s-manifest-ignition_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
#                      Switch to gelenable                           APR-2022 #
#                      Manage Az password  replication slowness      JUN-2022 #
#                      Get OCP pull-secret from Azure Keyvault       OCT-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# location where OCP manifests will reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
# source of OCP  templates
OCP_ASSETS_DIR="/home/cloud-user/${GIT_WKSHP_PROJECT}/assets/OCP"

#Location of the OCP pull-secret
KEYVAULT_NAME=gel-keyvault
SECRET_NAME=gel-ocp-pull-secret

configureAzureAuth () {
    # OCP only supports logging in with a password, not a certificate.
    # Create (add) a short-lived password.
    END_DATE=$(date '+%Y-%m-%dT%H:%M:%SZ+0000' --date='Next Saturday 1PM')
    RESULT=$(az ad sp credential reset --name ${AZURE_CLIENT_ID} --end-date ${END_DATE} --append)
    AZ_PASSWD=$(echo $RESULT | jq -r .password)
    cat > ~/.azure/osServicePrincipal.json << EOF
{
 "subscriptionId":"${AZURE_SUBSCRIPTION_ID}",
 "clientId":"${AZURE_CLIENT_ID}",
 "clientSecret":"${AZ_PASSWD}",
 "tenantId":"${AZURE_TENANT_ID}"
}
EOF
    # give AAD time to synch the new password
    sleep 30
    # test that the new password is valid
    az login --service-principal \
        --tenant "${AZURE_TENANT_ID}" \
        --username "${AZURE_CLIENT_ID}" \
        --password "${AZ_PASSWD}"
    rc=$?
    for i in {1..6}
    do if [[ ${rc} == 0 ]]; then break; fi
       logit "   Unable to login to Azure with newly created password. Trying again in 30s - Retry $i"
       sleep 30s;
       az login --service-principal \
            --tenant "${AZURE_TENANT_ID}" \
            --username "${AZURE_CLIENT_ID}" \
            --password "${AZ_PASSWD}"
        rc=$?
    done
    # do not abort here - give it one more chance with the subsequent code
    # [[ ${rc} == 0 ]] || return ${_ABORT_CODE}
}

getPullSecret() {
    local _mysecret
    local _found

    _mysecret=$(az keyvault secret show --name ${SECRET_NAME} --vault-name ${KEYVAULT_NAME} --query "value" -o tsv)
    # sometimes I got back an empty value. Retry
    _found=false
    for i in {1..5}
    do if [[ -n "${_mysecret}" ]]; then _found=true; break; fi
       sleep 60s;
       _mysecret=$(az keyvault secret show --name ${SECRET_NAME} --vault-name ${KEYVAULT_NAME} --query "value" -o tsv)
    done

    # return the value to the caller
    echo "$_mysecret"
}

createOCPManifests () {
    local _found
    logit "creating OCP manifests in ${CLUSTERCONF_DIR}"
    # export all variables from the vars.txt file
    set -a
    source /opt/gellow_work/vars/vars.txt
    set +a

    # get OCP pull-secret, admin public key, then substitute variables with values in OCP yaml
    OCP_PULL_SECRET=$(getPullSecret) \
    SSH_KEY_CLUSTER="$(cat /home/cloud-user/.ssh/cloud-user_id_rsa.pub)" \
    envsubst <${OCP_ASSETS_DIR}/install-config.yaml > ${CLUSTERCONF_DIR}/install-config.yaml

    # early abort if the pull secret is empty
    grep -q "auths" ${CLUSTERCONF_DIR}/install-config.yaml || return ${_ABORT_CODE}

    # archive the install-config.yaml file, since it will be deleted by the openshift-install command
    cp "${CLUSTERCONF_DIR}/install-config.yaml" "${WORK_DIR}/vars/install-config.yaml.$(date +%s)"

    # use OCP installer to create manifest
    sudo -E -u root bash -c "cd ${CLUSTERCONF_DIR};\
        openshift-install create manifests \
            --dir=${CLUSTERCONF_DIR} \
            --log-level=debug"

    #check that it worked - up to 15 minutes
    _found=false
    for i in {1..15}
    do if [[ -f ${CLUSTERCONF_DIR}/manifests/cluster-config.yaml ]]; then _found=true; break; fi
       logit "  Artifacts not found at ${CLUSTERCONF_DIR}. Trying again in 1 minute - Retry $i"
       sleep 60s;
       # use OCP installer to create manifest
       sudo -E -u root bash -c "cd ${CLUSTERCONF_DIR};\
           openshift-install create manifests \
               --dir=${CLUSTERCONF_DIR} \
               --log-level=debug"
    done
    #abort if it did not work
    ${_found} || return ${_ABORT_CODE}

    # the next two steps are required because we create the machines manually
    # remove the manifest files that define the control plane machines:
    rm -f ${CLUSTERCONF_DIR}/openshift/99_openshift-cluster-api_master-machines-*.yaml
    # remove the manifest files that define the worker plane machines:
    rm -f ${CLUSTERCONF_DIR}/openshift/99_openshift-cluster-api_worker-machineset-*.yaml

    # Remove the Public DNS in any case, because OCP cannot manage a DNS zone in a different subscription.
    # gelenable.sas.com DNS is in Azure. Find the ID:
    #publicDNS_ID=$(az network dns zone list --resource-group "gel_dns" --subscription "${AZURE_GEL_SUBSCRIPTION_ID}" --query "[?name=='${BASE_DOMAIN}'].[id]" -o tsv)

    #if [[ -z "${publicDNS_ID}" ]]; then
        # Public DNS is not stored in Azure. Remove 2 lines so that OCP will not try to manage it.
        # Sudents will have to perform DNS registration in https://names.na.sas.com.
        sed -i '/^.*publicZone.*$/,/^.*Microsoft\.Network\/dnszones.*$/d' \
            ${CLUSTERCONF_DIR}/manifests/cluster-dns-02-config.yml
    #else
        # Tell OCP to use the gelenable DNS
    #    sed -i "s|id: .*Microsoft\.Network\/dnszones.*$|id: ${publicDNS_ID}|" \
    #        ${CLUSTERCONF_DIR}/manifests/cluster-dns-02-config.yml
    #fi

    # get generated OCP infrastructure ID
    OCP_INFRA_ID=$(yq4 e '.status.infrastructureName' ${CLUSTERCONF_DIR}/manifests/cluster-infrastructure-02-config.yml)
    add_update_VARS_FILE OCP_INFRA_ID
    # fix a manifest file to match names
    sed -i -e "s|${OCP_INFRA_ID}-nsg|${AZURE_INFRA_RG}-nsg|" \
        -e "s|${OCP_INFRA_ID}-node-routetable|${AZURE_INFRA_RG}-node-routetable|" \
        ${CLUSTERCONF_DIR}/manifests/cloud-provider-config.yaml

    # archive the directory, since it will be deleted by the openshift-install command
    cp -R "${CLUSTERCONF_DIR}/" "${WORK_DIR}/vars/clusterconfig.$(date +%s)"

    # use OCP installer to create Ignition configuration files
    # this will remove the manifests created in the previous step
    sudo -E -u root bash -c "cd ${CLUSTERCONF_DIR};\
        openshift-install create ignition-configs \
            --dir=${CLUSTERCONF_DIR} \
            --log-level=debug"

    # workaround: RACE blocks access to API on port 6443. Redirecting on 443.
    sed -i 's|:6443|:443|g' ${CLUSTERCONF_DIR}/auth/kubeconfig
}

deleteOCPManifests () {
    logit "removing OCP manifests from ${CLUSTERCONF_DIR}"
    [ -d ${CLUSTERCONF_DIR} ] && \
    rm -rf ${CLUSTERCONF_DIR}
    logit "removing Service Principal password from cache"
    [ -f ~/.azure/osServicePrincipal.json ] && \
    rm -f ~/.azure/osServicePrincipal.json
}

validateOCPManifests () {
    #for both tests, abort if it fails
    validate -t 30 -s 4 -c "ls -l ${CLUSTERCONF_DIR}/*.ign" || return ${_ABORT_CODE}
    validate -t 30 -s 4 -c "ls -l ${CLUSTERCONF_DIR}/auth"|| return ${_ABORT_CODE}
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            configureAzureAuth

            rm -fr ${CLUSTERCONF_DIR}
            sudo -u cloud-user mkdir -p ${CLUSTERCONF_DIR}

            createOCPManifests
            # abort only if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && notifyandabort "ERROR: Failure creating OCP manifests" && exit ${_ABORT_CODE}

            validateOCPManifests
            # abort only if the function aborted
            [[ $? == ${_ABORT_CODE} ]] && notifyandabort "ERROR: Failure creating OCP manifests" && exit ${_ABORT_CODE}
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteOCPManifests
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateOCPManifests
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac