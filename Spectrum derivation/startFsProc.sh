#!/bin/bash

SETTINGS_FOLDER="./settings/"
SIGNAL_FOLDER="./rx_sig/"
USER="user1"
MASK="0"

function usage() {
    echo "Usage: $0 -s <settings_folder> -g <signal_folder> -u <USER> -m <MASK>"
    echo "  -s <settings_folder>   Specify the settings folder path"
    echo "  -g <signal_folder>     Specify the signal folder path"
    echo "  -u <USER>              Specify the user"
    echo "  -m <MASK>              Specify the mask value"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:g:u:m:h" opt; do
    case ${opt} in
        s )
            SETTINGS_FOLDER=$OPTARG
            ;;
        g )
            SIGNAL_FOLDER=$OPTARG
            ;;
        u )
            USER=$OPTARG
            ;;
        m )
            MASK=$OPTARG
            ;;
        h )
            usage
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done

matlab -batch "startProcessing('$SETTINGS_FOLDER', '$SIGNAL_FOLDER', '$USER', '$MASK')"