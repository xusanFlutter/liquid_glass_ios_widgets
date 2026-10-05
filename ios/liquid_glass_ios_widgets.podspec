Pod::Spec.new do |s|
  s.name             = 'liquid_glass_ios_widgets'
  s.version          = '0.2.0'
  s.summary          = 'Native iOS 26 Liquid Glass components as Flutter widgets.'
  s.description      = <<-DESC
Wraps native iOS Liquid Glass (SwiftUI / UIKit) components as Flutter widgets
via platform views.
                       DESC
  s.homepage         = 'https://github.com/xusanFlutter/liquid_glass_ios_widgets'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Husan' => 'startolibov@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'liquid_glass_ios_widgets/Sources/liquid_glass_ios_widgets/**/*.swift'
  s.resource_bundles = { 'liquid_glass_ios_widgets_privacy' => ['liquid_glass_ios_widgets/Sources/liquid_glass_ios_widgets/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.frameworks = 'SwiftUI', 'UIKit'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
