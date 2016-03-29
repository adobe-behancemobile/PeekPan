Pod::Spec.new do |s|
  s.name         = 'PeekPan'
  s.version      = '0.0.1'
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author       = { 'Brian Chon' => 'chon@adobe.com' }
  s.homepage     = 'https://github.com/adobe-behancemobile/PeekPan'
  s.summary      = 'PeekPan combines 3D Touch and pan gestures to cycle through a collection of views while Peeking.'
  s.ios.platform = :ios, '9.0'
  s.ios.deployment_target 	= '8.0'
  s.source       = { :git => 'https://github.com/adobe-behancemobile/PeekPan.git', :tag => s.version.to_s }
  s.source_files = 'PeekPan/PeekPan/*.{h, swift}'
  s.framework    = 'UIKit'
  s.requires_arc = true
end
