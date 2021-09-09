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
### ios prepare_release
```
fastlane ios prepare_release
```
Prepare release

#### Options

 * **`version`** (required): The new version of the framework

 * **`api_token`** (required): Github API token
### ios prepare_snapshot
```
fastlane ios prepare_snapshot
```
Prepare snapshot
### ios build_core
```
fastlane ios build_core
```
Build xcframework for distribution
### ios build_xcframework
```
fastlane ios build_xcframework
```
Build any project xcframework
### ios create_github_draft
```
fastlane ios create_github_draft
```
Upload to a github release draft
### ios update_plist_versions
```
fastlane ios update_plist_versions
```
Update version number in project plists
### ios update_readme_versions
```
fastlane ios update_readme_versions
```
Update version numbers in README.adoc
### ios update_badge
```
fastlane ios update_badge
```
Update readme badge
### ios generate_docs
```
fastlane ios generate_docs
```
Generate docs per version using Asciidoctor

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
