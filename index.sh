#!/bin/bash

STORE_NAME="$1"
STORE_ID="$2"
WEBSITE_ID="$3"
BASE_URL="$4"
COMPANY_NAME="$5"
APP_ICON_FILE="$6"
STORE_NAME_WITHOUT_SPACES=$(echo $STORE_NAME | tr -d ' ')
BRANCH_NAME="store-$STORE_NAME_WITHOUT_SPACES"
# directories
DIR_CODEBASE="storespal-client-ios/"
DIR_APP_ICON_OUTPUT="output/"

generatAppIcons() {
    sh ios_icon_generator.sh $APP_ICON_FILE $DIR_APP_ICON_OUTPUT
}

createNewTarget() {
    chmod +x ../ios_target_handler.rb
    ruby ../ios_target_handler.rb "$STORE_NAME" $STORE_ID $WEBSITE_ID $BASE_URL "$COMPANY_NAME"
}

copyAppIconFiles() {
    cp -fR ../output/ "ClientStore/Mobikul/Assets.xcassets/AppIcon$STORE_NAME_WITHOUT_SPACES.appiconset"
}

prepareRepository() {
    git clone 'https://github.com/SaeeSA/storespal-client-ios.git'
}

managePullRequest() {
    git checkout -b $BRANCH_NAME
    git status
    git add .
    git commit -m "Created new store $STORE_NAME"
    git push --set-upstream origin $BRANCH_NAME
}

cleanup() {
    cd ..
    ls
    rm -rf $DIR_APP_ICON_OUTPUT
    rm -rf $DIR_CODEBASE
}

generatAppIcons
# prepareRepository
cd $DIR_CODEBASE
createNewTarget
pod install
copyAppIconFiles
managePullRequest
# cleanup
# echo $STORE_NAME $APP_ICON_FILE


