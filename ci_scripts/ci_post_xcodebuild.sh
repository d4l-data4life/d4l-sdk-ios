#!/bin/sh


if [ "$CI_XCODEBUILD_ACTION" = "test-without-building" ];
then
    brew install sonar-scanner

    cd $CI_WORKSPACE

    echo "derived data/build/products ls"
    ls -altri $CI_TEST_PRODUCTS_PATH
    
    xcrun llvm-profdata merge $CI_DERIVED_DATA_PATH/Build/ProfileData/*/*.profdata -output merged.profdata
    xcrun --run llvm-cov show $CI_TEST_PRODUCTS_PATH/Debug-iphonesimulator/Data4LifeSDK.framework/Data4LifeSDK --instr-profile merged.profdata >> sonarqube-swift-coverage
    
    if [[ -n $CI_PULL_REQUEST_NUMBER ]];
    then
        sonar-scanner -Dsonar.login=$SONAR_TOKEN -Dsonar.pullrequest.base=$CI_PULL_REQUEST_TARGET_BRANCH -Dsonar.pullrequest.branch=$CI_PULL_REQUEST_SOURCE_BRANCH -Dsonar.pullrequest.key=$CI_PULL_REQUEST_NUMBER -Dsonar.pullrequest.provider=GitHub
    else
        sonar-scanner -Dsonar.login=$SONAR_TOKEN  
    fi
fi 

exit 0