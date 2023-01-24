#!/bin/bash
###############################################################################
#        Name: GEL.034.Create.OCP.Manifests                                   #
# Description: Create the OCP manifests required for OCP installation         #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-user-infra-generate-k8s-manifest-ignition_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# location where OCP manifests will reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
# source of OCP  templates
OCP_ASSETS_DIR="$(dirname $0)/../../../assets/OCP"

configureAzureAuth () {
    # workaround until I found how to use a client cert with OCP.
    AZ_PASSWD=$(curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/PSGEL300_Secret.txt)
    cat > ~/.azure/osServicePrincipal.json << EOF
{
 "subscriptionId":"${AZURE_SUBSCRIPTION_ID}",
 "clientId":"${AZURE_CLIENT_ID}",
 "clientSecret":"${AZ_PASSWD}",
 "tenantId":"${AZURE_TENANT_ID}"
}
EOF
}

createOCPManifests () {
    logit "creating OCP manifests in ${CLUSTERCONF_DIR}"
    # export all variables from the vars.txt file
    set -a
    source /opt/gellow_work/vars/vars.txt
    set +a

    # get OCP pull-secret, admin public key, then substitute variables with values in OCP yaml
    OCP_PULL_SECRET=$(curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/pull-secret.json) \
    SSH_KEY_CLUSTER="$(cat /home/cloud-user/.ssh/cloud-user_id_rsa.pub)" \
    envsubst <${OCP_ASSETS_DIR}/install-config.yaml > ${CLUSTERCONF_DIR}/install-config.yaml
    # archive the install-config.yaml file, since it will be deleted by the openshift-install command
    cp "${CLUSTERCONF_DIR}/install-config.yaml" "${WORK_DIR}/vars/install-config.yaml.$(date +%s)"

    configureAzureAuth

    # use OCP installer to create manifest
    sudo -E -u root bash -c "cd ${CLUSTERCONF_DIR};\
        openshift-install create manifests \
            --dir=${CLUSTERCONF_DIR} \
            --log-level=debug"

    #check that it worked
    for i in {1..6}
    do if [[ -f ${CLUSTERCONF_DIR}/manifests/cluster-config.yaml ]]; then break; fi
       logit "  Artifacts not found at ${CLUSTERCONF_DIR}. Sleeping $i: 10s"
       sleep 10s;
    done

    # the next two steps are required because we create the machines manually
    # remove the manifest files that define the control plane machines:
    rm -f ${CLUSTERCONF_DIR}/openshift/99_openshift-cluster-api_master-machines-*.yaml
    # remove the manifest files that define the worker plane machines:
    rm -f ${CLUSTERCONF_DIR}/openshift/99_openshift-cluster-api_worker-machineset-*.yaml

    # SAS public DNS is not stored in Azure. Remove 2 lines so that OCP will not try to manage it.
    # Sudents will have to perform DNS registration in https://names.na.sas.com.
    sed -i '/^.*publicZone.*$/,/^.*Microsoft\.Network\/dnszones.*$/d' \
        ${CLUSTERCONF_DIR}/manifests/cluster-dns-02-config.yml

    # get generated OCP infrastructure ID
    OCP_INFRA_ID=$(yq4 e '.status.infrastructureName' ${CLUSTERCONF_DIR}/manifests/cluster-infrastructure-02-config.yml)
    add_update_VARS_FILE OCP_INFRA_ID
    # fix a manifest file to match names
    sed -i -e "s|${OCP_INFRA_ID}-nsg|${AZURE_INFRA_RG}-nsg|" \
        -e "s|${OCP_INFRA_ID}-node-routetable|${AZURE_INFRA_RG}-node-routetable|" \
        ${CLUSTERCONF_DIR}/manifests/cloud-provider-config.yaml

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
}

validateOCPManifests () {
    validate -t 30 -s 4 -c "ls -l ${CLUSTERCONF_DIR}/*.ign"
    validate -t 30 -s 4 -c "ls -l ${CLUSTERCONF_DIR}/auth"
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            rm -fr ${CLUSTERCONF_DIR}
            sudo -u cloud-user mkdir -p ${CLUSTERCONF_DIR}
            createOCPManifests
            validateOCPManifests
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