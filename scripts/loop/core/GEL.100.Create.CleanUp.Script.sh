#!/bin/bash
##############################################################################################
#        Name: GEL.100.Create.CleanUp.Script                                                 #
# Description: When a RACE reservation ends, the SIMS daemon wiil call any                   #
#              script existing in /var/opt/sims/finalshutdown                                #
#              This script places a cleanup script there to delete all Azure artifacts       #
# ------------------------------------------------------------------------------------------ #
# Edoardo Riva,        Initial release,                                             NOV-2021 #
#                      Enhancement                                                  MAY-2022 #
##############################################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

SIMS_FINAL_DIR=/var/opt/sims/finalshutdown/


createCleanUp () {
    mkdir -p ${SIMS_FINAL_DIR}

    cat > ${SIMS_FINAL_DIR}/deleteWorkshop.sh << EOF
#!/bin/bash
#${SIMS_FINAL_DIR}/deleteWorkshop.sh

#Send notificatio to MSTeams channel
python3 /opt/gellow_code/scripts/gel_tools/teams-chat-post.py -u ${gellow_webhook} -l "WARNING" -m "NOTE: Final Shutdown - Starting CleanUp"

#Remove LDAP Connection (including the Network Security Group rules used to control network access to Azure ADDS.)
bash /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/scripts/loop/gelenable/GEL.052.Configure.OCP.Auth.sh clean
#Remove app DNS
bash /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/scripts/loop/gelenable/GEL.050.Register.Apps.DNS.sh clean
#Remove API DNS
bash /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/scripts/loop/gelenable/GEL.036.Create.Azure.LoadBalancer.sh clean
#Remove the Service Principal and the RG - in practice, removes all
bash /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/scripts/loop/gelenable/GEL.032.Azure.Pre.Cluster.sh clean
# Logout from AZ
bash /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/scripts/loop/gelenable/GEL.015.Define.Environment.and.Login.sh clean
EOF
    chmod +x ${SIMS_FINAL_DIR}/deleteWorkshop.sh
}

deleteCleanUp () {
    [[ -f ${SIMS_FINAL_DIR}/deleteWorkshop.sh ]] && rm -f ${SIMS_FINAL_DIR}/deleteWorkshop.sh
}

validateCleanUp () {
    validate -t 15s -s 5 -c "ls -l ${SIMS_FINAL_DIR}/deleteWorkshop.sh"
}

runCleanUp () {
    [[ -f ${SIMS_FINAL_DIR}/deleteWorkshop.sh ]] && ${SIMS_FINAL_DIR}/deleteWorkshop.sh
}

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            createCleanUp
        fi
    ;;
    'stop')
        if isFirstHost ; then
            runCleanUp
        fi
    ;;
    'clean')
        if isFirstHost ; then
            deleteCleanUp
        fi
    ;;
    'update')
    ;;
    'validate')
        if isFirstHost ; then
            validateCleanUp
        fi
    ;;
    'list')
    ;;
    *)
        printf '\nThe parameter %s does not do anything in the script %s \n' "$1" "$(basename "$0")"
        exit 1
    ;;
esac