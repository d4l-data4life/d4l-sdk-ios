# Data4LifeSDK for iOS
Pure Swift API client for HealthCloud that automatically handles encryption

[![CocoaPods Compatible](https://img.shields.io/badge/pod-v1.13.1-blue.svg)](https://github.com/CocoaPods/CocoaPods)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/apple/swift-package-manager)
[![License](https://img.shields.io/badge/license-PRIVATE-blue.svg)](https://github.com/d4l-data4life/d4l-sdk-ios/blob/main/LICENSE)

## Usage
### Requirements
* Xcode 12
* iOS 13.0+
* Swift 5.3+

### Dependencies
* [Alamofire](https://github.com/Alamofire/Alamofire)
* [then](https://github.com/freshOS/then)
* [AppAuth](https://github.com/openid/AppAuth-iOS)
* [Data4LifeFHIR](https://github.com/d4l-data4life/d4l-fhir-ios)
* [ModelsR4](https://github.com/d4l-data4life/d4l-fhir-ios)
* [Data4LifeSDKUtils](https://github.com/d4l-data4life/d4l-utils-ios)
* [Data4LifeCrypto](https://github.com/d4l-data4life/d4l-sdk-ios/tree/master/Crypto)

*Note*: `Data4LifeCrypto` is part of the SDK project as a separate framework

## Installation

#### CocoaPods

To install with [CocoaPods](https://cocoapods.org/) add the following line to the podfile.

```ruby
source 'https://github.com/d4l-data4life/d4l-cocoapods-specs.git'

pod 'Data4LifeSDK', '~> 1.13.1'
```

**Note**: For more info check [README](https://github.com/d4l-data4life/d4l-cocoapods-specs/blob/master/README.md).

#### Swift Package Manager

To install with Swift package manager, select your project’s Swift Packages tab, and add our repository url, either as ssh or https url:

```
https://github.com/d4l-data4life/d4l-sdk-ios.git
```
OR
```
git@github.com:d4l-data4life/d4l-sdk-ios.git
```

In the next step, select the latest version, and then import both the `Data4LifeCrypto` and `Data4LifeSDK` libraries in your target.

## Building

### Building Requirements

=== Config files

Before you are able to run tests on the SDK or run the example app, you need to create and add a `d4l-example-app-config.json` file in the project root folder with credentials (which can only be obtained by contacting us).
NOTE: The CI expects this configuration from an environment variable stored in the GitHub secret: `D4L_EXAMPLE_CONFIG_IOS`

The configuration file has the following structure:

```
// d4l-example-app-config.json
{
  "platform": "d4l",
  "configs": {
    "DEVELOPMENT": {
      "id": "{CLIENT_ID}",
      "secret": "{CLIENT_SECRET}",
      "redirectScheme": "{CLIENT_REDIRECT_SCHEME}"
    },
    "SANDBOX": {
      "id": "{CLIENT_ID}",
      "secret": "{CLIENT_SECRET}",
      "redirectScheme": "{CLIENT_REDIRECT_SCHEME}"
    },
    "STAGING": {
      "id": "{CLIENT_ID}",
      "secret": "{CLIENT_SECRET}",
      "redirectScheme": "{CLIENT_REDIRECT_SCHEME}"
    },
    "PRODUCTION": {
      "id": "{CLIENT_ID}",
      "secret": "{CLIENT_SECRET}",
      "redirectScheme": "{CLIENT_REDIRECT_SCHEME}"
    }
  }
}
```

In order for the example app to choose which environment to use, you need to change the build setting `D4L_CONFIGURATION` on the Example target, and set any of the following values:
DEVELOPMENT, SANDBOX, STAGING, PRODUCTION

### Example application
Open `HCSDK.xcodeproj` and run the `Example` target.

## Management
SDK is handled by [Fastlane](https://fastlane.tools/) and all of the available functions are available in the [README](fastlane/README.md).

### Install Fastlane and other dependencies using Bundler

```sh
bundle install
```
*Note*: Check [official page](https://bundler.io/) for info on how to install Bundler.

### Release framework

#### Manual steps
Updating [CHANGELOG.md](CHANGELOG.md) is the only required manual step, release script expects to find matching version in the CHANGELOG.md as the one that used while calling `release_framework` Fastlane action. It takes all of the chnages and uploads them to the GitHub release page.

*Note*: Release script will fail if there is no new version defined in the changelog

#### Running the script
Folowing command will release new version of framework while handling couple of things:

* Set new project version
* Set new SDK version
* Set new version in the README.md
* Update CocoaPods `podspec` file
* Generate new documentation
* Do sanity checks (proper branch, proper version number in changelog etc.)
* Commit changes and create version tag
* Push new commit and tag to GitHub
* Create GitHub release page with all of the information for [CHANGELOG.md](CHANGELOG.md)
* Upload prebuilt framework to the release page
* Push latest `podspec`s to private [CococaPods specs repository](https://github.com/d4l-data4life/d4l-cocoapods-specs)

```sh
bundle exec fastlane release_framework version:"1.0.0" crypto_version:"1.0.0" api_token:"super-secret-GitHub-API-token"
```

### Generate documentation

Documentation is generated using Asciidoctor, all of the resoures can be found in [asciidoc](asciidoc/), and generated HTML documentation can be found in [docs](docs/).

```sh
bundle exec fastlane generate_docs version:1.0.0
```
