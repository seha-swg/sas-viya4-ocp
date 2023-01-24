#!/bin/bash
###############################################################################
#        Name: GEL.048.Post.OCP.Workers                                       #
# Description: Approving the certificate signing requests for worker machines #
#                                                                             #
# See https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-approve-csrs_installing-azure-user-infra #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
# Edoardo Riva,        Split DNS regisitration in another script     APR 2022 #
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

approveCertificates () {
    logit "Approving certificate signing requests. Step 1."
    oc --kubeconfig ${KUBECONFIG} get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc --kubeconfig ${KUBECONFIG} adm certificate approve
    logit "Waiting up to 10 minutes for worker nodes to become pending"

    # detect if worker nodes come online
    for i in {1..20}
    do
        sleep 30
        # just in case other CSR came in after the first approval
        oc --kubeconfig ${KUBECONFIG} get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc --kubeconfig ${KUBECONFIG} adm certificate approve
        # count number of workers and compare to what is expected
        WORKERS_CNT=$(oc --kubeconfig ${KUBECONFIG} get nodes | tr -s ' ' | cut -f 3 -d ' ' | grep 'worker' | wc -l)
        if [ ${WORKER_REPLICAS} -eq ${WORKERS_CNT} ]; then break; fi
        logit " ... waiting ${i} ..."
    done
    logit "Expected ${WORKER_REPLICAS} workers, detected ${WORKERS_CNT}"

    # approve workers CSR
    logit "Waiting up to 10 minutes for worker nodes to become ready"
    for i in {1..10}
    do
        oc --kubeconfig ${KUBECONFIG} get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc --kubeconfig ${KUBECONFIG} adm certificate approve
        # count number of workers ready and compare to what is expected
        WORKERS_CNT=$(oc --kubeconfig ${KUBECONFIG} get nodes -l "node-role.kubernetes.io/worker" | tr -s ' ' | cut -f 2 -d ' ' | grep '^Ready' | wc -l)
        if [ ${WORKER_REPLICAS} -eq ${WORKERS_CNT} ]; then break; fi
        logit " ... waiting ${i} ..."
        sleep 60
    done
    logit "Expected ${WORKER_REPLICAS} workers in the ready status, detected ${WORKERS_CNT}"
}

waitForInstallComplete () {
    logit "Waiting up to 50 minutes until the cluster is ready - usually less than 15 minutes"
    openshift-install  --dir=${CLUSTERCONF_DIR} wait-for install-complete --log-level debug
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            approveCertificates
            waitForInstallComplete
        fi
    ;;
    'stop')
    ;;
    'clean')
    ;;
    'update')
    ;;
    'validate')
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac