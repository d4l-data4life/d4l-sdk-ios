Pod::Spec.new do |s|
  s.name             = "Data4LifeCrypto"
  s.version          = "1.5.0"
  s.summary          = "Swift framework for handling all of the crypto operation for PHDC iOS SDK."
  s.homepage         = "https://github.com/d4l-data4life/d4l-sdk-ios/"
  s.license          = { :type => 'LICENSE', :file => "LICENSE" }
  s.author           = { "D4L data4life gGmbH" => "contact@data4life.care" }

  s.source           = { :http => 'https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/XCFrameworks-1.13.0.zip' }
  s.swift_version    = '5.3'
  s.platform     = :ios, '12.0'
  s.requires_arc = true
  s.cocoapods_version = '>= 1.10.0'

  s.vendored_frameworks = 'Data4LifeCrypto.xcframework'
  s.preserve_paths      = 'Data4LifeCrypto.xcframework', 'Data4LifeCrypto.dSYMs/Data4LifeCrypto.framework.ios-arm64.dSYM', 'Data4LifeCrypto.dSYMs/Data4LifeCrypto.framework.ios-arm64_x86_64-simulator.dSYM'

  s.dependency 'Data4LifeSDKUtils', '0.4.0'
end
