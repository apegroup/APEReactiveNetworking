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
  s.summary          = 'A light-weight networking library based on ReactiveSwift 5.x'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A light-weight networking library based on ReactiveSwift 5.x

Features
PUT, POST, DELETE, GET, PATCH operations
Possibility to add custom request headers
Reactive oriented, based on ReactiveSwift 5.x
Automatically updates the network activity indicator
Possibility to customize authentication handler, default implementation saves JWT token in safe storage (Keychain)
100% Swift (Swift 3.X)
Powering Swift Generics
Access to all HTTP response headers
Lightweigth, less than 600 lines of code (including whitespace, comments and other meta lines)
Automatic retry mechanism with possiblity to define max number of retries (exponential back-off strategy)
Deterministic response time (successful, error or timeout), i.e. abort after 'X' seconds
Possibility to customize response code validation, default implementation accepts 200-299 codes
Code coverage at X %
Example project available, using all network methods and binding to UI (a full reactive chain)
                       DESC

  s.homepage         = 'https://github.com/apegroup/APEReactiveNetworking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dennis Charmington' => 'dennis.charmington@apegroup.com' }
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
