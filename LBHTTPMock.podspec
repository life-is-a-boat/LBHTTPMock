#
# Be sure to run `pod lib lint LBHTTPMock.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LBHTTPMock'
  s.version          = '1.0.0'
  s.summary          = 'A short description of LBHTTPMock.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/life-is-a-boat/LBHTTPMock'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'life-is-a-boat' => '15560028009@163.com' }
  s.source           = { :git => 'https://github.com/life-is-a-boat/LBHTTPMock.git', :branch => "/release/#{s.version}" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  
  s.static_framework = true

  s.module_name = 'LBHTTPMock'

  s.source_files = 'LBHTTPMock/Classes/**/*'

  s.public_header_files = 'LBHTTPMock/Classes/LBHTTPMockManager.h'
   
end
