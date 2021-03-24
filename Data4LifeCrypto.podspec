Pod::Spec.new do |s|
  s.name             = "Data4LifeCrypto"
  s.version          = "1.4.1"
  s.summary          = "Swift framework for handling all of the crypto operation for PHDC iOS SDK."
  s.homepage         = "https://github.com/d4l-data4life/d4l-sdk-ios/"
  s.license          = 'Private License'
  s.author           = { "D4L data4life gGmbH" => "contact@data4life.care" }
  s.source           = { :git => "https://github.com/d4l-data4life/d4l-sdk-ios.git", :tag => "1.12.2" }
  s.swift_version    = '5.3'

  s.platform     = :ios, '12.0'
  s.requires_arc = true

  s.source_files = 'Crypto/Sources/**/*.{swift,h,m}'

  s.dependency 'CryptoSwift', '1.3.7'
end
