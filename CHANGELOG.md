# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.13.0]
### Added
- Updated framework packaging to XCFrameworks
- Added support for Swift Package Manager

### Removed
- Removed support for iOS 12
- Removed dependency with CryptoSwift in Crypto Library and SDK
- Removes Carthage support

## [1.12.3] - 2021-02-23
### Changed
- Updated crypto dependency to be public

## [1.12.2] - 2021-02-23
### Fixed
- Fix for unfiltered search/count methods

## [1.12.1] - 2021-02-12
### Fixed
- Count methods will correctly count all resources when used without a type parameter
- Search / Count methods will be able to get resources also from legacy SDK versions

## [1.12.0] - 2021-01-22
### Added
All FHIR Stu3 methods are also available now for FHIR R4 models

### Fixed
Annotations are now treated like tags, so percent encoded / trimmed / lowercased.

### Changed
Changed repository to d4l

## [1.11.1] - 2020-11-18
### Fixed
- String encoding does not add double quotes around in iOS 13+  

## [1.11.0] - 2020-11-17
### Added
- Add support for annotations using `create`, `update`, `search` and `count` record methods

### Changed
- All AppData api calls now work with Data directly (or Codable resources)
- FhirRecord resource property is renamed to fhirResource
- SDKResource, ModelVersionInformation, FHIRVersionInformation, FHIRIdentifierType protocols are now internal

### Removed
- Removes AppDataModels library again in favor of using just Foundation Data

## [1.10.1] - 2020-11-10
- Adds support for JsonAppData
- Renames DonorKey to UserKey

## [1.10.0] - 2020-09-05
### Added
- Adds compatibility with XCode 12
- Upgrade to latest version of CryptoSwift
- Adds support for AppDataModels (DonorKey)

### Changed
- Replaced `accessToken` with `refreshedAccessToken` in `Data4lifeClient`

## [1.9.0] - 2020-09-02
### Added
- Adds public api to get access token
- Adds possibility to create/fetch/update/delete/count generic Data inside our backend

### Deprecated
- Renames `Record` to `FHIRRecord` (in order to differentiate with `AppDataRecord`)
- Renames `(create/fetch/update/delete/count)record(s)` functions to `(create/fetch/update/delete/count)FHIRRecord(s)`

## [1.8.0] - 2020-07-22
- Updates FHIR library to 0.14.0
- Added check for deprecated or unsupported SDK versions

## [1.7.1] - 2020-03-09
- Fixes app store submission issue

## [1.7.0] - 2020-02-10
### Added
- Implemented DI containers framework (internally)
- Implemented Generic Attachment Handling
- Possibility to specify a type when downloading records
- Introduced `Data4LifeSDKUtils` (0.1.5) for some common functions

### Changed
- Signature of public configureWith function
- Updated attachment size limit to 20 MB
- Attachment size/type validation will also be included by downloading attachments
- Included hash validation by downloading and uploading attachment
- Attachment methods could also be used for FHIRResources which include attachments (`DocumentReference`, `DiagnosticReport`, `Medication`, `Practitioner`, `Patient`, `Observation`, `ObservationComponent`, `Questionnaire`, `QuestionnaireResponse`, `QuestionnaireItem`, `QuestionnaireResponseItem`, `QuestionnaireResponseItemAnswer`)
- DocumentReference related specific operations (downloadRecord, downloadRecords) are now extended to all FHIR Resources
- It is possible to specify which resource type is being fetched in Fetch operations (fetchRecord, fetchRecords)
- `Data4LifeFHIR` is now version 0.11.1. It includes now all the FHIR Element Helpers methods (i.e. `Attachment.with(:)`), which got removed from the main SDK

### Removed
- All Domain Resource Helpers method are removed from the SDK and moved to a new framework called `Data4LifeFHIRProfiles` (v0.2.1).
In order to make this change, all the related SDK frameworks are updated (refer to migration section for changes).

### Migration

#### SDK Framework split
- `Data4LifeSDK` framework was split to better provide support for incoming FHIR Profiles features.
Structure is now the following:
  * `Data4LifeSDK` for use of FHIRResources within the D4L health data backend, and everything related to it (crypto, validation, authentication)
  * `Data4LifeFHIR` for all the FHIRResource definitions and the helpers for the Element subclasses.
  * `Data4LifeFHIRProfiles` for all the helpers for the DomainResource subclasses (and profiles in the future)
  * `Data4LifeSDKUtils` for common functionalities shared between the 3 libraries

The dependency chain is the following:
  * `Data4LifeSDK` imports `Data4LifeFHIR` and `Data4LifeSDKUtils`
  * `Data4LifeFHIRProfiles` imports `Data4LifeFHIR` and `Data4LifeSDKUtils`
Breaking therefore the connection between Data4LifeSDK and the helpers.

In order then to keep using all the domain resource helpers, both SDK and FHIRProfiles must be imported in an app.
To migrate and keep same functionalities:
  * Add `github "gesundheitscloud/hc-fhir-profiles-ios" == 0.2.1` on the Cartfile
  * Run `carthage update --platform ios --use-ssh`
  * Import manually (as Carthage installations go) the build `Data4LifeFHIRProfiles` and the `Data4LifeSDKUtils` frameworks.
  * Add `import Data4LifeFHIRProfiles` or/and `import Data4LifeFHIR` wherever any of the helpers are used

By doing this, all of the used api should be available as before.  

#### Changed Public Methods
- Function configureWith requires now an environment parameter, and setting the environment directly is not possible anymore:
This code in the previous version:
```
Data4LifeClient.configureWith(clientId: "id",
                              clientSecret: "secret",
                              redirectURLString: "url")
Data4LifeClient.environment = .staging`
```

  should be replaced by:
```
Data4LifeClient.configureWith(clientId: "id",
                              clientSecret: "secret",
                              redirectURLString: "url",
                              environment: .staging)
```

- All the `DocumentReference` operations are now extended to be used with all FHIRResources. This has the advantage that any resource can be downloaded (including eventual attachments) with the same method.
As a side effect, just by calling the method, swift cannot infer anymore which resource is being downloaded (in opposition from before, where it was always a DocumentReference).
Therefore in order to facilitate its use, an optional type parameter has been added to the function, so it can be specified which resource is being downloaded, i.e.:

  The following function:
```
Data4LifeClient.downloadRecord(withId: identifier) { ... }
```

  should be replaced by the following, in order to avoid boilerplate casting:
```                                              
Data4LifeClient.downloadRecord(withId: identifier, of: DocumentReference.self) { ... }                                                
```

- Same goes for fetch operations:
```
Data4LifeClient.fetchRecord(withId: identifier) { ... }
```

 should be replaced by the following, in order to avoid boilerplate casting:
```                                              
Data4LifeClient.fetchRecord(withId: identifier, of: DocumentReference.self) { ... }                                                
```

## [1.6.3] - 2019-12-13
### Fixed
- Fixed Renaming Bug for `AuthService`

## [1.6.2] - 2019-11-25
### Fixed
- Fixed der certificate import for cocoapods

## [1.6.1] - 2019-11-23
### Fixed
- Fixed Version plist import for cocoapods

## [1.6.0] - 2019-11-22
### Changed
- Renamed framework to `Data4LifeSDK`
- Renamed client to `Data4LifeClient`
- Renamed dependencies to `Data4LifeFHIR` and `Data4LifeCrypto`

### Migration
- Replace the module for the imports from `HCSDK` to `Data4LifeSDK`.
- Replace `HCSDKClient` with `Data4LifeClient`
- If you are using Cocoapods update your Podfile to use the `Data4LifeSDK` pod instead of `HCSDK`
- If you are using Carthage, remove Carthage directory and .resolved file, bootstrap, and after bootstrapping replace from Build Phases/Embed Carthage Framework the following frameworks HCFHIR.framework, HCCrypto.framework and HCSDK.framework to Data4LifeFHIR.framework, Data4LifeCrypto.framework and Data4LifeSDK.framework

### Added
- Ability to progress tracking and cancel option when attachments are being downloaded
- Ability to log to the console network requests in debug configurations.

### Fixed
- Present login screen in full screen mode for iOS 13

## [1.5.2] - 2019-10-09
### Fixed
Fixed Cocoapod dependencies

## [1.5.1] - 2019-10-02
### Fixed
- Renamed 'Then' library

## [1.5.0] - 2019-10-01
### Added
- Add common key id to `userInfo` object
- Store common key with specific common key id
- Download common key by a given common key id from the backend
- Encrypt record data and attachment key with the current common key
- Store `commonKeyId` on the record
- Fetch user info before creating or updating a record
- Introduce new spinner for login flow

## [1.4.1] - 2019-09-18
### Added
- Add support for `sandbox` environment

## [1.4.0] - 2019-09-18
### Added
- SDK support for iOS 13

### Fixed
- Resolved issue where attachments with similar content return wrong attachment id

## [1.3.0] - 2019-08-19
### Added
- Ability to automatically generate small and medium size image attachments and to allow their download when using `HCSDKClient.downloadAttachment(...)` and `HCSDKClient.downloadAttachments(...)`

## [1.1.1] - 2019-07-03
### Fixed
- Sharing keychain data when using `KeychainSharing` capability
- Loading of crypto material when used in the sharing extension

## [1.1.0] - 2019-06-17
### Added
- Ability to configure SDK with keychain group identifier that will be used for `KeychainSharing` capability
- Ability to configure SDK with app group identifier that will be used for `AppGroups` capability
- `KeychainSharing` and `AppGroups` can be used in combination to enable working SDK in the app extesions
- Ability to fetch single or a list of attachments
- Client method for downloading multiple `DocumentReference` records

### Changed
- SDK is now configured using `HCSDKClient.configureWith(...)` method instead of adding `HCSDK-Info.plist` to the project
- Upgrade login flow so there is no alert asking user to confirm that app can open the website

### Fixed
- Added the missing jpeg file signatures to support the missing jpeg file types

## [1.0.2] - 2019-05-10
### Fixed
- Resolved issue with activity indicator spinning forever in case user locks the screen while SDK is asking for prmissions to present login screen

## [1.0.1] - 2019-05-07
### Changed
- Expose `Environment` host information

### Changed
- Update UI branding
- Replace custom `Result` with one from `Foundation`
- Update project to Swift 5 and Xcode 10.2
- Crypto part of the project is moved into separate framework named `HCCrypto`

## [1.0.0] - 2019-04-01
### Added
- Attachment data file size limit
- Ability to update data of an existing attachment

### Changed
- Upgrade project to Swift 4.2
- SDK supports iOS 11 and above
- `userLoggedIn` renamed to `isUserLoggedIn`
- `countAll` and `countRecords` are fused into one method `countRecords(withType: FHIRResource?)` with optional type
- Renamed `Metadata.customCreationDate` to `Metadata.createdDate`
- `Metadata` date properties are non-optional

### Fixed
- Issue with changing environments
- JFIF MIME type validation
- Creating duplicate records when using batch methods

## [1.0.0-rc.4] - 2019-02-14
### Added
- Limited what types can be uploaded as attachment data, supported for now: `pdf`, `jpeg`, `tiff`, `png` and `dcm`.
- Session state change listener

### Changed
- Public API naming uses record instead of resource

## [1.0.0-rc.3] - 2018-12-21
### Added
- All resource models conform to `NSCopying` protocol
- SSL certificate public key pinning for available environments
- Staging environment
- Generic API for any FHIR resource
- Helper methods for easier handling of specific FHIR resources: `CarePlan`, `MedicationRequest`, `Medication`, `MedicationIngredient`, `Patient`, `Practitioner`, `Organization` and `Dosage`

### Changed
- Development environment endpoint

### Removed
- All of the custom models and related API calls (`Document`, `Report`, `Observation`)

## [1.0.0-rc.2] - 2018-07-11
### Fixed
- Document attachments are appended instead of prepended on update
- Uploading attachments with same data no longer have same identifier

### Changed
- Attachment content type property is a non-optional
- Observation value property is a non-optional

## [1.0.0-rc.1] - 2018-06-29
### Fixed
- Updating attachments overwrites old ones
- CocoaPods does not copy Info.plist and resources

## [1.0.0-rc] - 2018-06-21
### Added
- CocoaPods support
- Gesundheitscloud model versioning

### Changed
- Login screen UI
- Available environments
- Unified login result block with the rest of actions
- Document date handling:
  - Document `customDate` is now `customCreationDate` and used for `fetchDocuments` to include documents from and to this date. Date format is "yyyy-MM-dd"
  - `creationDate` is the documents creation date
  - `updatedDate` is the server side updated date

### Fixed
- Logout call performs API call

## [1.0.0-beta.1] - 2018-05-17
### Fixed
- OAuth scopes format

## [1.0.0-beta] - 2018-05-10
### Added
- AppAuth library for handling OAuth 2.0
- Crypto protocol for crypto operations

### Changed
- Client info configuration

### Removed
- ZeroKit library

## [0.5.1] - 2018-05-9
### Fixed
- Swift 4.1 issues
- Make all Observation properties public

## [0.5.0] - 2018-03-28
### Added
- Author model
- Batch delete API calls
- Batch update API calls
- Builder pattern for all models
- Connectivity manager for session monitoring
- Expose queue for recieving callbacks on all API calls
- Script for building slim framework (AppStore architectures only)

### Fixed
- Create and update Report API calls
- Delete tokens from keychain when no internet connection

### Changed
- Document model properties
- Observation model properties

## [0.4.0] - 2018-01-24
### Added
- Observation model
- Report model
- Batch download
- Batch upload
- Upload binary to GitHub on release
- Fetch number of uploaded records

### Changed
- Async user session check
- Fetch document renamed to download

### Fixed
- Keychain persisting data after SDK is uninstalled
- Document without attachment has no identifier

## [0.3.0] - 2017-12-13
### Added
- Add FHIR compatiblity
- Paginated fetch records with filters

### Changed
- Exposing documents instead of records

### Fixed
- Keychain not updating existing items

## [0.2.0] - 2017-11-01
### Added
- Update record with new document and/or tags
- Delete record

### Changed
- Add attachment to a document instead of a binary file
- Add multiple attachments to a document

### Fixed
- Carthage nested frameworks
- OAuth not refreshing access token

## [0.1.0] - 2017-10-07
### Added
- Implement login flow with a custom user interface
- User setup after first login
- Encryption and decryption of payload using ZeroKit
- Create and read records with a document resource
- Attach binary file to record
- Basic unit tests

[Unreleased]: https://github.com/d4l-data4life/d4l-sdk-ios/compare/1.12.3...main
[1.12.3]: https://github.com/d4l-data4life/d4l-sdk-ios/compare/1.12.2...1.12.3
[1.12.2]: https://github.com/d4l-data4life/d4l-sdk-ios/compare/1.12.1...1.12.2
[1.12.1]: https://github.com/d4l-data4life/d4l-sdk-ios/compare/1.12.0...1.12.1
[1.12.0]: https://github.com/d4l-data4life/d4l-sdk-ios/releases/tag/1.12.0
[1.11.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.11.0...1.11.1
[1.11.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.10.1...1.11.0
[1.10.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.10.0...1.10.1
[1.10.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.9.0...1.10.0
[1.9.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.8.0...1.9.0
[1.8.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.7.1...1.8.0
[1.7.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.7.0...1.7.1
[1.7.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.6.3...1.7.0
[1.6.3]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.6.2...1.6.3
[1.6.2]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.6.1...1.6.2
[1.6.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.6.0...1.6.1
[1.6.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.5.2...1.6.0
[1.5.2]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.5.1...1.5.2
[1.5.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.4.1...1.5.0
[1.4.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.1.1...1.3.0
[1.1.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-rc.4...1.0.0
[1.0.0-rc.4]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-rc.3...1.0.0-rc.4
[1.0.0-rc.3]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-rc.2...1.0.0-rc.3
[1.0.0-rc.2]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-rc.1...1.0.0-rc.2
[1.0.0-rc.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-rc...1.0.0-rc.1
[1.0.0-rc]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-beta.1...1.0.0-rc
[1.0.0-beta.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/1.0.0-beta...1.0.0-beta.1
[1.0.0-beta]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.5.1...1.0.0-beta
[0.5.1]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/gesundheitscloud/hc-sdk-ios/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/gesundheitscloud/hc-sdk-ios/releases/tag/0.1.0
