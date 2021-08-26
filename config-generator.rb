#!/usr/bin/env ruby

require 'json'

srcRoot = ENV["SRCROOT"]
configurationName = ENV["CONFIGURATION"]

jsonFile = File.read("#{srcRoot}/d4l-example-app-config.json")
serverConfigurations = JSON.parse(jsonFile)["configs"]

d4lConfigurationEntry = `xcodebuild -project #{srcRoot}/Data4LifeSDK.xcodeproj -showBuildSettings -configuration #{configurationName} | grep D4L_CONFIGURATION`
d4lConfiguration = d4lConfigurationEntry.split.last
currentServerConfiguration = serverConfigurations[d4lConfiguration]
identifier = currentServerConfiguration["id"]
secret = currentServerConfiguration["secret"]
urlScheme = currentServerConfiguration["redirectScheme"]
configFile = "//  Copyright (c) 2020 D4L data4life gGmbH
//  All rights reserved.
//
//  D4L owns all legal rights, title and interest in and to the Software Development Kit (SDK),
//  including any intellectual property rights that subsist in the SDK.
//
//  The SDK and its documentation may be accessed and used for viewing/review purposes only.
//  Any usage of the SDK for other purposes, including usage for the development of
//  applications/third-party applications shall require the conclusion of a license agreement
//  between you and D4L.
//
//  If you are interested in licensing the SDK for your own applications/third-party
//  applications and/or if you’d like to contribute to the development of the SDK, please
//  contact D4L by email to help@data4life.care.

D4L_ID = #{identifier}
D4L_SECRET = #{secret}
D4L_REDIRECT_SCHEME = #{urlScheme}
D4L_ENVIRONMENT = #{d4lConfiguration}
"
Dir.mkdir("#{srcRoot}/generated") unless Dir.exist?("#{srcRoot}/generated")
File.open("#{srcRoot}/generated/d4l-example.xcconfig", "w") { |f| f.write configFile }
