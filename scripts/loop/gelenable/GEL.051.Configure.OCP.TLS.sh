#!/bin/bash
###############################################################################
#        Name: GEL.051.Configure.OCP.TLS                                      #
# Description: Create TLS certificate and key for the server, signed with the #
#    GEL intermedaite CA (because the GEL Root CA cerificate is recognized by #
#    the machines used in this workshop). Then load the articats as K8s       #
#    secrets, to be used by OCP                                               #
# See https://docs.openshift.com/container-platform/4.10/security/certificates/replacing-default-ingress-certificate.html #
# See https://gitlab.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/blob/6124cfcf8971c50fa760f93ff20c1907c02922e4/scripts/jupyter/Auth_JupyterHub01.sh#L26-45 #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# location where OCP manifests reside
CLUSTERCONF_DIR=/home/cloud-user/project/clusterconfig
export KUBECONFIG=${CLUSTERCONF_DIR}/auth/kubeconfig

createPrivateKeyCert () {
    # Save artifacts in the TLS dir
    mkdir -p ${CLUSTERCONF_DIR}/TLS
    # Get cluster hostnames and IPs
    APPS_DN="apps.${CLUSTER_NAME}.${BASE_DOMAIN}"
    # APPS_IP should have been registered in the vars file by the previous script.
    logit "     Creating server TLS artifacts in ${CLUSTERCONF_DIR}/TLS"
    # Create private key and CSR
    openssl req -newkey rsa:2048 -sha256 -nodes \
        -keyout ${CLUSTERCONF_DIR}/TLS/openshift-ingress_key.pem \
        -extensions v3_ca \
        -config <(echo "[req]"; echo "distinguished_name=req"; echo "[v3_ca]"; echo "extendedKeyUsage=serverAuth"; echo "subjectAltName=DNS:${APPS_DN},DNS:*.${APPS_DN}") \
        -subj "/C=US/ST=NC/L=North Carolina/O=SAS/CN=${CLUSTER_NAME}.${BASE_DOMAIN}" \
        -out ${CLUSTERCONF_DIR}/TLS/openshift-ingress_server.csr
    # Sign CSR with GEL Intermediate CA
    openssl x509 -req -sha256 -extensions v3_ca \
        -extfile <(echo "[v3_ca]"; echo "extendedKeyUsage=serverAuth"; echo "subjectAltName=DNS:${APPS_DN},DNS:*.${APPS_DN}") \
        -days 820 \
        -in ${CLUSTERCONF_DIR}/TLS/openshift-ingress_server.csr \
        -CA /opt/gellow_code/scripts/loop/viya4/gelenv/TLS/GELEnvRootCA/intermediate.cert.pem \
        -CAkey /opt/gellow_code/scripts/loop/viya4/gelenv/TLS/GELEnvRootCA/intermediate.key.pem \
        -CAcreateserial \
        -out ${CLUSTERCONF_DIR}/TLS/openshift-ingress_cert.pem
    # Add full chain to certificate file
    cat ${CLUSTERCONF_DIR}/TLS/openshift-ingress_cert.pem > ${CLUSTERCONF_DIR}/TLS/openshift-ingress_chain.pem
    cat /opt/gellow_code/scripts/loop/viya4/gelenv/TLS/GELEnvRootCA/intermediate.cert.pem >> ${CLUSTERCONF_DIR}/TLS/openshift-ingress_chain.pem
    cat /opt/gellow_code/scripts/loop/viya4/gelenv/TLS/GELEnvRootCA/ca_cert.pem >> ${CLUSTERCONF_DIR}/TLS/openshift-ingress_chain.pem
}

loadTLSSecret () {
    logit "     Creating TLS secret in OCP openshift-config namespace"

    # Create a config map that includes only the root CA certificate used to sign the wildcard certificate
    oc --kubeconfig ${KUBECONFIG} create configmap sasgel-ca \
        --from-file=ca-bundle.crt=/opt/gellow_code/scripts/loop/viya4/gelenv/TLS/GELEnvRootCA/ca_cert.pem \
        -n openshift-config
    # Update the cluster-wide proxy configuration
    oc --kubeconfig ${KUBECONFIG} patch proxy/cluster \
        --type=merge \
        --patch='{"spec":{"trustedCA":{"name":"sasgel-ca"}}}'
    # Create the TLS secret with private key and chain
    oc --kubeconfig ${KUBECONFIG} delete secret openshift-ingress-gel \
        --ignore-not-found \
        -n openshift-ingress
    oc --kubeconfig ${KUBECONFIG} create secret tls openshift-ingress-gel \
        --cert=${CLUSTERCONF_DIR}/TLS/openshift-ingress_chain.pem \
        --key=${CLUSTERCONF_DIR}/TLS/openshift-ingress_key.pem \
        -n openshift-ingress
    # Update the Ingress Controller configuration with the newly created secret
    oc --kubeconfig ${KUBECONFIG} patch ingresscontroller.operator default \
     --type=merge -p \
     '{"spec":{"defaultCertificate": {"name": "openshift-ingress-gel"}}}' \
     -n openshift-ingress-operator
}

deletePrivateKeyCert () {
    rm -rf ${CLUSTERCONF_DIR}/TLS
}

deleteTLSSecret () {
    return
}

validateClusterTLS () {
    validate -s 7 -t 22s -c "oc --kubeconfig ${KUBECONFIG} auth can-i create projects --as ${CLUSTER_ADMIN_NAME}"
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createPrivateKeyCert
            loadTLSSecret
        fi
    ;;
    'stop')
    ;;
    'clean')
        if isFirstHost ; then
            deleteTLSSecret
            deletePrivateKeyCert
        fi
    ;;
    'update')
    ;;
    'validate')
        validateClusterTLS
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac