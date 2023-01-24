#!/bin/bash
###############################################################################
#        Name: GEL.060.Create.Storage.Class                                   #
# Description: Create an Azure Files storage class                            #
#              to be used by SAS Viya for RWX volumes                         #
# See: https://docs.openshift.com/container-platform/4.7/storage/dynamic-provisioning.html#azure-file-definition_dynamic-provisioning #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              NOV-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
export KUBECONFIG=${CLUSTERCONF_DIR}/auth/kubeconfig

# source of OCP templates
OCP_ASSETS_DIR="$(dirname $0)/../../../assets/OCP"

PROJECT_DIR=/home/cloud-user/project/storage

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

copyfiles (){
    # cleanup
    [[ -d ${PROJECT_DIR} ]] && rm -rf ${PROJECT_DIR}
    mkdir -p ${PROJECT_DIR}
    chmod 777 ${PROJECT_DIR}
    chown cloud-user ${PROJECT_DIR}
    # copy and customize storageClass definition file
    sed -e "s|{{ STORAGE_ACCOUNT }}|${AZURE_SA_NAME}|" \
        ${OCP_ASSETS_DIR}/storageClass-AzureFile.yaml \
        > ${PROJECT_DIR}/storageClass-AzureFile.yaml
    # copy RBAC and test files
    cp ${OCP_ASSETS_DIR}/storageRBAC.yaml ${PROJECT_DIR}/
    cp ${OCP_ASSETS_DIR}/storageTest.yaml ${PROJECT_DIR}/
}
createStorageClass (){
    # create the storageClass
    logit "creating custom sas storageClass"
    oc --kubeconfig ${KUBECONFIG} apply -f ${PROJECT_DIR}/storageClass-AzureFile.yaml
}

configureRBAC () {
    logit "granting required permissions to system:serviceaccount:kube-system:persistent-volume-binder"
    oc --kubeconfig ${KUBECONFIG} apply -f ${OCP_ASSETS_DIR}/storageRBAC.yaml
}

validateStorageClass () {
    validate -t 30 -s 10 -c "oc get sc | grep sas"
}

cleanUp () {
    logit "deleting custom sas storageClass, removing RBAC permissions, and removing ${PROJECT_DIR}"
    [[ -f ${PROJECT_DIR}/storageClass-AzureFile.yaml ]] && oc delete -f ${PROJECT_DIR}/storageClass-AzureFile.yaml
    [[ -f ${PROJECT_DIR}/storageRBAC.yaml ]] && oc delete -f ${PROJECT_DIR}/storageRBAC.yaml
    [[ -d ${PROJECT_DIR} ]] && rm -rf ${PROJECT_DIR}
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            copyfiles
            createStorageClass
            configureRBAC
            validateStorageClass
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            cleanUp
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateStorageClass
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac