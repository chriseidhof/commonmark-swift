#
#  Be sure to run `pod spec lint CommonMark.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "CommonMark"
  s.version      = "0.0.5"
  s.summary      = "CommonMark is a Swift wrapper around cmark (a C-based parser for CommonMark)"

  s.description  = <<-DESC
                   This library provides a Swift interface to the cmark library. Rather than working with C function pointers, it exposes the Markdown as an abstract syntax tree (an enum). It allows for parsing, modification and rendering of a CommonMark document.
                   DESC


  s.homepage     = "https://github.com/chriseidhof/commonmark-swift"


  s.license      = "MIT"

  s.author             = { "Chris Eidhof" => "chris@eidhof.nl" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source       = { :git => "https://github.com/chriseidhof/commonmark-swift.git", :tag => "0.0.5" }

  s.source_files  = "CommonMark/*.swift", "CommonMark/CommonMark.h"

  s.dependency "cmark", '0.21'
end
