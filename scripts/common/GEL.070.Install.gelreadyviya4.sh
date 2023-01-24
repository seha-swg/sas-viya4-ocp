#!/bin/bash
###############################################################################
#        Name: GEL.070.Install.gelreadyviy4.sh                                #
# Description: Call the optional script from GELLOW to install gelreadyviy4   #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              NOV-2021 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE} )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

myScript=$(find ${CODE_DIR}/scripts/loop/viya4/ -iname *optional*install*gelreadyviya4* -type f)

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            sudo -E bash ${myScript} gelreadyviya4-install
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