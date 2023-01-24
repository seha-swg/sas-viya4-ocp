#!/bin/bash
###############################################################################
#        Name: GEL.010.Define.Environment.sh                                  #
# Description: Ensure project variables are set for the workshop              #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
# Edoardo Riva,        Switch to gelenable                           MAR-2022 #
# Edoardo Riva,        uplevel to OCP 4.10                           AUG-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

#Unique ID of this worksop
GELENABLE_WORKSHOP_CODE="PSGEL300"

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "${GELENABLE_WORKSHOP_CODE}" ]]; then exit; fi

# Directory where Viya Artifacts will be created
PROJECT=gelocp

# OCP Version and release. Used to download OC CLI and installer - see https://mirror.openshift.com/pub/openshift-v4/clients/ocp
OCPVersion=4.10
OCPRelease=stable-${OCPVersion}

# OCP Cluster name - lowercase
CLUSTER_NAME=${short_race_hostname,,}

# Number of OCP worker nodes
WORKER_REPLICAS=5

# OCP Image Name
OCP_IMAGE_NAME=PSGEL300-OCP-410

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost; then

            sudo -u cloud-user mkdir -p /home/cloud-user/project/${PROJECT}

            add_update_VARS_FILE GELENABLE_WORKSHOP_CODE
            add_update_VARS_FILE OCPVersion
            add_update_VARS_FILE OCPRelease
            add_update_VARS_FILE CLUSTER_NAME
            add_update_VARS_FILE WORKER_REPLICAS
            add_update_VARS_FILE OCP_IMAGE_NAME
        fi
    ;;
    'stop')
    ;;
    'clean')
        [ -n "${PROJECT}" ] && \
        [ -d /home/cloud-user/project/${PROJECT} ] && \
        sudo -u cloud-user rm -rf /home/cloud-user/project/${PROJECT}
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
