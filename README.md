# Data4LifeSDK for iOS
Pure Swift API client for HealthCloud that automatically handles encryption

[![CocoaPods Compatible](https://img.shields.io/badge/pod-v1.12.0-blue.svg)](https://github.com/CocoaPods/CocoaPods)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/license-PRIVATE-blue.svg)](https://github.com/d4l-data4life/d4l-sdk-ios/blob/main/LICENSE)

## Documentation

Current documentation can be found on [GitHub Pages](https://d4l-data4life.github.io/d4l-sdk-ios/1.12.0).

## Usage
### Requirements
* Xcode 12
* iOS 12.0+
* Swift 5.3+

### Dependencies
* [Alamofire](https://github.com/Alamofire/Alamofire)
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
* [then](https://github.com/freshOS/then)
* [AppAuth](https://github.com/openid/AppAuth-iOS)
* [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)
* [Data4LifeFHIR](https://github.com/d4l-data4life/d4l-fhir-ios)
* [ModelsR4](https://github.com/d4l-data4life/d4l-fhir-ios)
* [Data4LifeSDKUtils](https://github.com/d4l-data4life/d4l-utils-ios)
* [Data4LifeCrypto](https://github.com/d4l-data4life/d4l-sdk-ios/tree/master/Crypto)

*Note*: `Data4LifeCrypto` is part of the SDK project as a separate framework

## Installation

#### CocoaPods

You can use [CocoaPods](https://cocoapods.org/).

```ruby
pod 'Data4LifeSDK', '~> 1.12.0'
```

#### Carthage

You can use [Carthage](https://github.com/Carthage/Carthage).
Specify in Cartfile:

```ruby
github "d4l-data4life/d4l-sdk-ios"
```

Run `carthage` to build the framework and drag the built Data4LifeSDK.framework into your Xcode project. Follow [build instructions](https://github.com/Carthage/Carthage#getting-started).

## Building

#### Install Carthage

```sh
brew install carthage
```
*Note*: For other installation methods check [README](https://github.com/Carthage/Carthage#installing-carthage).

#### Build frameworks

*Note*: Since from XCode 12 Carthage packaging does not work anymore, please use the script [README](https://github.com/Carthage/Carthage#installing-carthage).
```sh
./wcarthage.sh bootstrap --use-ssh --platform iOS
```
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
* Push latest `podspec` to private [CococaPods specs repository](https://github.com/d4l-data4life/d4l-cocoapods-specs)

```sh
bundle exec fastlane release_framework version:"1.0.0" api_token:"super-secret-GitHub-API-token"
```

### Generate documentation

Documentation is generated using Asciidoctor, all of the resoures can be found in [asciidoc](asciidoc/), and generated HTML documentation can be found in [docs](docs/).

```sh
bundle exec fastlane generate_docs version:1.0.0
```
