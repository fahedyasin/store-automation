#!/bin/bash

STORE_NAME="$1"
STORE_ID="$2"
WEBSITE_ID="$3"
BASE_URL="$4"
COMPANY_NAME="$5"
APP_ICON_FILE="$6"

# directories
DIR_CODEBASE="storespal-client-ios/"
DIR_APP_ICON_OUTPUT="output/"

generatAppIcons() {
    sh ios_icon_generator.sh $APP_ICON_FILE $DIR_APP_ICON_OUTPUT
}

createNewTarget() {
    chmod +x ../ios_target_handler.rb
    ruby ../ios_target_handler.rb "Fahed Store" 11 22 https://dev.satorespal.com "StoresPal" 1024.png
}

prepareRepository() {
    git clone 'https://github.com/SaeeSA/storespal-client-ios.git'
}

cleanup() {
    cd ..
    ls
    rm -rf $DIR_APP_ICON_OUTPUT
    rm -rf $DIR_CODEBASE
}

# prepareRepository
# generatAppIcons
cd $DIR_CODEBASE
createNewTarget

# cleanup
echo $STORE_NAME $APP_ICON_FILE

