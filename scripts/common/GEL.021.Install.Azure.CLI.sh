#!/bin/bash
###############################################################################
#        Name: Install the Azure CLI                                          #
# Description: Call the optional script from GELLOW to install Azure CLI      #
# --------------------------------------------------------------------------- #
# Edoardo Riva,        Initial release,                              OCT-2021 #
#                 pin version to 2.36 due to 2.37 breacking changes  MAY-2022 #
###############################################################################
#set -x

# Get common collateral ------------------------------------------------
FUNCTION_FILE=/opt/gellow_code/scripts/common/common_functions.shinc
source <( cat ${FUNCTION_FILE}  )

# only run when part of the PSGEL300 workshop
if [[ "${GIT_WKSHP_CODE^^}" != "PSGEL300" ]]; then exit; fi

# Breaking changes between 2.36 and 2.37:
# https://docs.microsoft.com/en-us/cli/azure/microsoft-graph-migration?tabs=powershell
# https://docs.microsoft.com/en-us/cli/azure/release-notes-azure-cli?toc=%2Fcli%2Fazure%2Ftoc.json&bc=%2Fcli%2Fazure%2Fbreadcrumb%2Ftoc.json#role
# to list valid versions see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=dnf#install-specific-version
export AZVersion="2.36.0"

myScript=$(find ${CODE_DIR}/scripts/loop/viya4/ -iname *optional*az*cli* -type f)

case "$1" in
    'enable')
    ;;
    'start')
        if isFirstHost ; then
            logit "Installing Azure CLI"
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