#
# Be sure to run `pod lib lint Klendario.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Purchaser'
  s.version          = File.read('VERSION')
  s.summary          = 'A set of Swift classes to simplify In-App Purchases implementation'

  s.description      = <<-DESC
Purchaser is a set of classes written in Swift to help iOS developers to simplify the process of implementing In-App purchases in their applications.
                       DESC

  s.homepage         = 'https://github.com/thxou/Purchaser'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'thxou' => 'yo@thxou.com' }
  s.source           = { :git => 'https://github.com/thxou/Purchaser.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Source/**/*'
  
end
