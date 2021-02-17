#!/bin/bash

STORE_NAME="$1"
PRIVACY_POLICY_URL="$2"
MARKETING_URL="$3"
FEEDBACK_EMAIL="$4"
TARGET_NAME=$(echo $STORE_NAME | tr -d ' ')
BUNDLE_ID="com.storespal.$TARGET_NAME"

# directories
DIR_CODEBASE="storespal-client-ios/"


runFastlane() {
    cp -fR ../fastlane/ fastlane/
    cp -fR ../Gemfile .

    # append .env file
    echo "
PRODUCE_APP_IDENTIFIER=$BUNDLE_ID
MATCH_APP_IDENTIFIER=$BUNDLE_ID
DELIVER_APP_IDENTIFIER=$BUNDLE_ID
DISTRIBUTE_PRIVACY_POLICY_URL=$PRIVACY_POLICY_URL
DISTRIBUTE_MARKETING_URL=$MARKETING_URL
DISTRIBUTE_FEEDBACK_EMAIL=$FEEDBACK_EMAIL" >> fastlane/.env

    # append .env.ios file
    echo "
FL_PROJECT_SIGNING_TARGETS=$TARGET_NAME
GYM_SCHEME=$TARGET_NAME" >> fastlane/.env.ios

    bundle install
    bundle exec fastlane pilot import -c fastlane/testers/pak_office.csv -a $BUNDLE_ID -g "Pak Office"
    bundle exec fastlane pilot import -c fastlane/testers/jeddah_office.csv -a $BUNDLE_ID -g "Jeddah Office"
    bundle exec fastlane ios distribute
}

cleanup() {
    cd ..
    ls
    rm -rf $DIR_APP_ICON_OUTPUT
    rm -rf $DIR_CODEBASE
}

cd $DIR_CODEBASE
runFastlane
# cleanup



