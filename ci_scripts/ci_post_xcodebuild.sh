#!/bin/sh

xcrun llvm-profdata merge $CI_DERIVED_DATA_PATH/Build/ProfileData/*/*.profdata -output merged.profdata
xcrun --run llvm-cov show $CI_DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Data4LifeSDK.framework/Data4LifeSDK --instr-profile merged.profdata >> sonarqube-swift-coverage

if [[ -n $CI_PULL_REQUEST_NUMBER ]];
then
    sonar-scanner -Dsonar.login=$SONAR_TOKEN -Dsonar.pullrequest.base=$CI_PULL_REQUEST_TARGET_BRANCH -Dsonar.pullrequest.branch=$CI_PULL_REQUEST_SOURCE_BRANCH -Dsonar.pullrequest.key=$CI_PULL_REQUEST_NUMBER -Dsonar.pullrequest.provider=GitHub
else
    sonar-scanner -Dsonar.login=$SONAR_TOKEN  
fi

exit 0