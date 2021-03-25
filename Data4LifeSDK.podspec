Pod::Spec.new do |s|
  s.name             = "Data4LifeSDK"
  s.version          = "1.12.3"
  s.summary          = "iOS SDK for interacting with the Gesundheitscloud health data backend."
  s.homepage         = "https://github.com/d4l-data4life/d4l-sdk-ios/"
  s.license          = 'Private License'
  s.author           = { "D4L data4life gGmbH" => "contact@data4life.care" }
  s.source           = { :git => "https://github.com/d4l-data4life/d4l-sdk-ios.git", :tag => s.version }
  s.swift_version    = '5.3'

  s.platform     = :ios, '12.0'
  s.requires_arc = true

  s.source_files = 'SDK/Sources/**/*.{swift,h,m}'
  s.resources = 'SDK/Sources/Certificates/*.cer', 'SDK/Sources/Certificates/*.der', 'SDK/Sources/Data4LifeSDK-Version.plist'

  s.dependency 'Alamofire', '~> 5.4.1'
  s.dependency 'thenPromise', '~> 5.1.3'
  s.dependency 'AppAuth', '~> 1.0.0'
  s.dependency 'Data4LifeSDKUtils', '~> 0.3.1'
  s.dependency 'Data4LifeCrypto', '~> 1.4.1'

  s.dependency 'Data4LifeFHIR', '~> 0.18.1'
  s.dependency 'ModelsR4', '~> 0.18.1'
end
