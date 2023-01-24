#!/bin/bash
###############################################################################
#        Name: Install the OCP CLI                                            #
# Description: Call the optional script from GELLOW to install OCP CLI        #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

myScript=$(find ${CODE_DIR}/scripts/loop/viya4/ -iname *optional*ocp*cli* -type f)

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            logit "Installing OCP CLI"
            sudo -E bash ${myScript} install
        fi
    ;;
    'stop')
    ;;
    'clean')
        sudo -E bash ${myScript} clean
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