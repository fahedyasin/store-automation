#!/bin/bash

STORE_NAME="$1"
STORE_ID="$2"
WEBSITE_ID="$3"
BASE_URL="$4"
COMPANY_NAME="$5"
APP_ICON_FILE="$6"
PRIVACY_POLICY_URL="$7"
MARKETING_URL="$8"
FEEDBACK_EMAIL="$9"
TARGET_NAME=$(echo $STORE_NAME | tr -d ' ')
BRANCH_NAME="store-$TARGET_NAME"
BUNDLE_ID="com.storespal.$TARGET_NAME"
SKU=$(echo $STORE_NAME | tr [a-z] [A-Z])
SKU=$(echo ${SKU// /_})

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
    cp -fR ../output/ "ClientStore/Mobikul/Assets.xcassets/AppIcon$TARGET_NAME.appiconset"
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
    gh pr create -t "Store $STORE_NAME" -b "Created new store"
}

prepareFastlane() {
    cp -fR ../fastlane/ fastlane/
    cp -fR ../Gemfile .

    # append .env file
    echo "
PRODUCE_APP_IDENTIFIER=$BUNDLE_ID
MATCH_APP_IDENTIFIER=$BUNDLE_ID
DELIVER_APP_IDENTIFIER=$BUNDLE_ID
PRODUCE_APP_NAME=$STORE_NAME
PRODUCE_SKU=$SKU
DISTRIBUTE_PRIVACY_POLICY_URL=$PRIVACY_POLICY_URL
DISTRIBUTE_MARKETING_URL=$MARKETING_URL
DISTRIBUTE_FEEDBACK_EMAIL=$FEEDBACK_EMAIL" >> fastlane/.env

# append .env.ios file
    echo "
FL_PROJECT_SIGNING_TARGETS=$TARGET_NAME
GYM_SCHEME=$TARGET_NAME" >> fastlane/.env.ios

# update app name in metadata
    echo "$STORE_NAME" > fastlane/metadata/en-US/name.txt

    bundle install
    bundle exec fastlane create_app
    bundle exec fastlane produce associate_merchant -a $BUNDLE_ID merchant.com.saee.scannerApplePayLive
    bundle exec fastlane ios release
    bundle exec fastlane ios submit_review
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
# managePullRequest
prepareFastlane
# cleanup
# echo $STORE_NAME $APP_ICON_FILE


