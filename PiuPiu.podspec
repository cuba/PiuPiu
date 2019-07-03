#
#  Be sure to run `pod spec lint PiuPiu.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name             = "PiuPiu"
  spec.version          = "1.3.1"
  spec.summary          = "A swift framework for easily making network calls and serializing them to objects."
  spec.description      = <<-DESC
                        This framework introduces the concept of futures to iOS. It is intended to make netwoking calls cleaner and simpler and provides the developer with more customizability then any other networking framework.
                        DESC
  spec.homepage         = "https://github.com/cuba/PiuPiu"
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "Jacob Sikorski" => "jacob.sikorski@gmail.com" }
  spec.platform         = :ios, "8.0"
  spec.swift_version    = "5.0"
  spec.source           = { :git => "https://github.com/cuba/PiuPiu.git", :tag => "#{spec.version}" }
  spec.source_files     = "Source", "Source/**/*.swift"
  spec.exclude_files    = "Example"
end
