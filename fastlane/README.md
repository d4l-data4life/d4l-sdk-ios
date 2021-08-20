fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Run unit tests and upload code coverage
### ios release_framework
```
fastlane ios release_framework
```
Package and release framework

#### Options

 * **`version`** (required): The new version of the framework

 * **`api_token`** (required): Github API token

 * **`allow_dirty_branch`**: Allows the git branch to be dirty before continuing. Defaults to false

 * **`remote`**: The name of the git remote. Defaults to `origin`. (`DEPLOY_REMOTE`)

 * **`allow_branch`**: The name of the branch to build from. Defaults to `master`. (`DEPLOY_BRANCH`)

 * **`skip_git_pull`**: Skips pulling the git remote. Defaults to false

 * **`is_prerelease`**: Marks GitHub release as Pre-release. Defaults to false
### ios test_podspec
```
fastlane ios test_podspec
```
Test podspec integration
### ios build_xcframeworks
```
fastlane ios build_xcframeworks
```
Build xcframework for distribution
### ios build_project_xcframework
```
fastlane ios build_project_xcframework
```
Build any project xcframework
### ios build_crypto_xcframework
```
fastlane ios build_crypto_xcframework
```
Build xcframework for distribution
### ios build_sdk_xcframework
```
fastlane ios build_sdk_xcframework
```
Build xcframework for distribution
### ios gh_release
```
fastlane ios gh_release
```
Upload to a github release
### ios update_plist_versions
```
fastlane ios update_plist_versions
```
Update AppStore and GCSDK version number in project plists
### ios lint
```
fastlane ios lint
```
Lint sources using swiftlint and check the license headers
### ios lint_headers
```
fastlane ios lint_headers
```
Check license headers
### ios update_readme_versions
```
fastlane ios update_readme_versions
```
Update version numbers in README.md
### ios update_sdk_podspec_version
```
fastlane ios update_sdk_podspec_version
```
Update Data4LifeSDK podspec version
### ios update_crypto_podspec_version
```
fastlane ios update_crypto_podspec_version
```
Update Data4LifeCrypto podspec version
### ios push_sdk_podspec
```
fastlane ios push_sdk_podspec
```
Push new Data4LifeSDK podspec files to private spec repo
### ios push_crypto_podspec
```
fastlane ios push_crypto_podspec
```
Push new Data4LifeCrypto podspec files to private spec repo
### ios generate_docs
```
fastlane ios generate_docs
```
Generate docs per version using Asciidoctor

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
