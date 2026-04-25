#!/bin/bash

#############################################################
#
# This script enables you to modify and compile *.aidl files
# without executing stable-aidl commands like
# "m <package>-update-api" and "m <package>-freeze-api", thus
# to avoid too many aidl versions generated at development
# phase.
#
# Details about stable-aidl, refer to
# https://source.android.google.cn/docs/core/architecture/aidl/stable-aidl?hl=en
#
# This script must be placed under aidl HAL directory, i.e.,
# hardware/interfaces/automotive/audiocontrol/aidl/
# hardware/interfaces/audio/aidl/
#
# Author : huang_qi_di@hotmail.com
# Date   : 05/28/2025
#
#############################################################

COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_GREEN='\033[0;32m'
COLOR_CLEAR='\033[0m'

checkRunningContext() {
    PREREQUISITE_DIR_EXPECTED=2
    PREREQUISITE_DIR_FOUND=0

    #echo Checking if prerequisite dirctories exist...

    if [ -d ./aidl_api ]; then
        #echo aidl_api found.
        PREREQUISITE_DIR_FOUND=$(($PREREQUISITE_DIR_FOUND+1))
    else
        echo aidl_api dir not found!
    fi

    if [ -d ./android ]; then
        #echo android found.
        PREREQUISITE_DIR_FOUND=$(($PREREQUISITE_DIR_FOUND+1))
    else
        echo android dir not found!
    fi

    if [ $PREREQUISITE_DIR_EXPECTED -eq $PREREQUISITE_DIR_FOUND ]; then
        echo All prerequisites found. Good to go!
        echo ------------------------------------
        echo
    else
        echo -e ${COLOR_RED}Error: Prerequisites not met! Please put this script under correct path then retry.${COLOR_CLEAR}
        echo
        exit 1
    fi

}


SELECTD_API_IDX=1

selectApiToUpdate() {
    echo Select an API number to be updated from below list:

    echo -e ${COLOR_YELLOW}
    ls -1 aidl_api | awk '{print NR,$0}'
    echo -e ${COLOR_CLEAR}

    echo ------------------------------------
    read -p "Waiting for input: " SELECTED_API_IDX
    SELECTED_API_IDX=$(echo $SELECTED_API_IDX | cut -d " " -f 1)

    SELECTED_API_NAME=$(ls -1 aidl_api | awk 'NR==api_idx' api_idx=$SELECTED_API_IDX)

    #echo Selected idx=$SELECTED_API_IDX, name=$SELECTED_API_NAME

}


DIR_DEV_AIDL=""
MAX_API_VER=1
DIR_MAX_API_AIDL=""
DIR_CURRENT_API_AIDL=""

composeAidlFileDirectory() {

    API_DIR_COUNT=$(ls aidl_api/$SELECTED_API_NAME | wc -w)

    MAX_API_VER=$(($API_DIR_COUNT-1))

    DIR_MAX_API="./aidl_api/$SELECTED_API_NAME/"$MAX_API_VER
    DIR_CURRENT_API="./aidl_api/$SELECTED_API_NAME/current"

    DIR_SUB_AIDL_FILES=$(echo $SELECTED_API_NAME | sed 's#\.#/#g')

    DIR_MAX_API_AIDL=$DIR_MAX_API/$DIR_SUB_AIDL_FILES
    DIR_CURRENT_API_AIDL=$DIR_CURRENT_API/$DIR_SUB_AIDL_FILES

    DIR_DEV_AIDL=$DIR_SUB_AIDL_FILES

    echo
    echo Below AIDL files will be used for this update:
    echo ./$DIR_DEV_AIDL
    echo

    ls $DIR_DEV_AIDL
    echo

    echo Targets:
    echo
    echo $DIR_MAX_API_AIDL
    echo $DIR_CURRENT_API_AIDL
    echo

}


copyAidlFiles() {
    cp $DIR_DEV_AIDL/*.aidl $DIR_MAX_API_AIDL/
    cp $DIR_DEV_AIDL/*.aidl $DIR_CURRENT_API_AIDL/

}


DIR_ANDROID_ROOT=""
RETRY_COUNT=20

findAndroidRootDir() {
    RETRY_COUNT=$(($RETRY_COUNT-1))
    if [ $RETRY_COUNT -eq 0 ]; then
        echo -e ${COLOR_RED}Error: Unable to locate Android root directory! Please put this script under correct path then retry.${COLOR_CLEAR}
        echo
        exit 1
    fi

    #echo Searching for Android root dir: $(pwd)
    DIR_HW_FOUND=$(
        pwd | awk -F "/" '{
            if($NF=="interfaces" && $(NF-1)=="hardware"){
                print "1"
            }else{
                print "0"
            }
        }'
    )

    if [ $DIR_HW_FOUND -eq 1 ]; then
        if [ ! -e ../../build/envsetup.sh ]; then
            DIR_HW_FOUND=0
        fi
    fi

    #echo DIR_HW_FOUND=$DIR_HW_FOUND
    if [ $DIR_HW_FOUND -eq 1 ]; then
        cd ../..
        DIR_ANDROID_ROOT=$(pwd)
        echo Detected DIR_ANDROID_ROOT=$DIR_ANDROID_ROOT
        echo
    else
        cd ..
        findAndroidRootDir
    fi

}


updateHashFile() {

    DIR_SCRIPT_ROOT=$(pwd)
    #echo $DIR_SCRIPT_ROOT

    findAndroidRootDir

    OUT_HASH_FILE=$DIR_ANDROID_ROOT/out/soong/.intermediates/hardware/interfaces/automotive/audiocontrol/aidl/$SELECTED_API_NAME-api/checkhash_$MAX_API_VER.timestamp

    echo OUT_HASH_FILE=$OUT_HASH_FILE

    if [ -e $OUT_HASH_FILE ]; then
        rm $OUT_HASH_FILE
        echo Hash cache file cleared.
    fi

    cd $DIR_SCRIPT_ROOT/$DIR_MAX_API

    OLD_HASH=$(cat ./.hash)

    # API hash value is calculated per aidlVerifyHashRule at https://android.googlesource.com/platform/system/tools/aidl/+/refs/tags/aml_med_340922010/build/aidl_api.go#47

    HASH_OBFUSCATOR="latest-version"
    if [ $MAX_API_VER -gt 1 ]; then
        HASH_OBFUSCATOR=$(($MAX_API_VER-1))
    fi
    echo HASH_OBFUSCATOR=$HASH_OBFUSCATOR

    NEW_HASH=$({ find ./ -name "*.aidl" -print0 | LC_ALL=C sort -z | xargs -0 sha1sum && echo $HASH_OBFUSCATOR; } | sha1sum | cut -d " " -f 1)

    echo
    echo OLD_HASH=$OLD_HASH
    echo NEW_HASH=$NEW_HASH

    echo $NEW_HASH > ./.hash

}


main() {
    echo

    checkRunningContext
    selectApiToUpdate
    composeAidlFileDirectory
    copyAidlFiles
    updateHashFile

    echo
    echo -e ${COLOR_GREEN}=== Update Done ===${COLOR_CLEAR}
    echo

}

main


