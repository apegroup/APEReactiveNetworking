#
# Be sure to run `pod lib lint APEReactiveNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'APEReactiveNetworking'
  s.version          = '2.0.3'
  s.summary          = 'APEReactiveNetworking is simply a reactive oriented, feather-weight networking library, made by Sweden'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  APEReactiveNetworking is simply a reactive oriented, feather-weight networking library, made by Sweden.

  We focused on building a network lib that was real-world, use-case oriented (looking at what our existing app projects actually used/needed from a networking lib) rather than implementing all sorts of functions any given project would possibly use.

  It's feather-weight because we deliberately did not implement features, available in other networking libs, that is seldom used, for example multipart request-body support. Why create waste?

  It's reactive based because we built it on top of ReactiveSwift, which is an aswesome lib that we think will be the best Reactive lib for the Apple platforms.

  We also added functions that we needed but missed in other network libraries, such as deterministic timeout time for a given request with built-in retry mechanism (eg: Send request X with maximum 5 retries and an exponential backoff-strategy staring at 1 second, but cancel everything and timeout after maximum 10 seconds, no mather how many retries have been executed)

  APEReactiveNetworking is implemented purley in Swift 3 and powering the magic of Swift Generics.
                       DESC

  s.homepage         = 'https://github.com/apegroup/APEReactiveNetworking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Apegroup AB' => 'dennis.charmington@apegroup.com' }
  s.source           = { :git => 'https://github.com/apegroup/APEReactiveNetworking.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/apegroup'

  s.ios.deployment_target = '9.0'

  s.source_files = 'APEReactiveNetworking/Source/**/*'
  
  # s.resource_bundles = {
  #   'APEReactiveNetworking' => ['APEReactiveNetworking/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ReactiveSwift', '1.0.0-alpha.2'
  s.dependency 'Locksmith', '3.0.0'
end