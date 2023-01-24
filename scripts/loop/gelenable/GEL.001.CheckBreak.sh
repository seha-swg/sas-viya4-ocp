#!/bin/bash
###############################################################################
#        Name: Check and Break                                                #
# Description: Check the comment for the keyword to force an early exit       #
#               still runs all of gellow, but not the workshop scripts        #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

checkAndExit () {
    if [[ ${race_coll_comment} == *"_WKSHPBREAK_"* ]]; then
        MSG="NOTE: User-requested workshop scripts halt. The word _WKSHPBREAK_ was found in the comment of the RACE reservation."
        logit "${MSG}"
        python3 /opt/gellow_code/scripts/gel_tools/teams-chat-post.py -u ${gellow_webhook} -l "WARNING" -m "${MSG}"
        exit ${_ABORT_CODE}
    fi
}

case "$1" in
    'enable')
    ;;
    'start')
        checkAndExit
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