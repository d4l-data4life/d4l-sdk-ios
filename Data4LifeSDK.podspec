Pod::Spec.new do |s|
  s.name             = "Data4LifeSDK"
  s.version          = "1.13.0"
  s.summary          = "iOS SDK for interacting with the Gesundheitscloud health data backend."
  s.homepage         = "https://github.com/d4l-data4life/d4l-sdk-ios/"
  s.license          = { :type => 'LICENSE', :file => "LICENSE" }
  s.author           = { "D4L data4life gGmbH" => "contact@data4life.care" }

  s.source           = { :http => 'https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/' + s.version.to_s + '/XCFrameworks-' + s.version.to_s + '.zip' }
  s.swift_versions   = ['5.3']
  s.platform         = :ios, '13.0'
  s.requires_arc     = true
  s.cocoapods_version = '>= 1.10.0'
  s.resources = 'SDK/Sources/Certificates/*.cer', 'SDK/Sources/Certificates/*.der', 'SDK/Sources/Data4LifeSDK-Version.plist'
  s.vendored_frameworks = 'Data4LifeSDK.xcframework'
  s.preserve_paths      = 'Data4LifeSDK.xcframework', 'Data4LifeSDK.dSYMs/Data4LifeSDK.framework.ios-arm64.dSYM', 'Data4LifeSDK.dSYMs/Data4LifeSDK.framework.ios-arm64_x86_64-simulator.dSYM'

  s.dependency 'Alamofire', '~> 5.4.1'
  s.dependency 'thenPromise', '~> 5.1.3'
  s.dependency 'AppAuth', '~> 1.4.0'
  s.dependency 'Data4LifeSDKUtils', '~> 0.4.0'
  s.dependency 'Data4LifeCrypto', '~> 1.5.0'
  s.dependency 'Data4LifeFHIR', '~> 0.19.0'
  s.dependency 'ModelsR4', '~> 0.19.0'
end
