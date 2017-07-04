
Pod::Spec.new do |s|
  s.name             = 'CSNetty'
  s.version          = '0.0.1'
  s.summary          = 'CSNetty is a powerful and elegant HTTP client framework for iOS/OSX. And the adopting of chaining syntax make it easy to use.'
  s.description      = <<-DESC
   It has many features:
   * Supports chain syntax and bath requests
   * Provides the cache mechenism and has various types of cache policy
   * Customs the different content-type with specific callback method
   * Monitors the progress of uploading and downloading during the time of requesting
                       DESC
  s.homepage         = 'https://github.com/Chasel-Shao/CSNetty.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chasel-Shao' => '753080265@qq.com' }
  s.source           = { :git => 'https://github.com/Chasel-Shao/CSNetty.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'

  s.source_files = 'CSNetty/*.{h,m}'
  s.public_header_files = 'CSNetty/*.{h}'
  s.frameworks = 'UIKit', 'CoreFoundation'
  s.dependency 'CSModel'
  
end
