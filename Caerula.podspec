Pod::Spec.new do |s|
  s.name             = 'Caerula'
  s.version          = '0.2.0'
  s.summary          = 'Beacon radar view for UIKit'
  s.description      = 'Scan iBeacon accessories and visualize in a view with UIKit dynamics animation.'
  s.homepage         = 'https://github.com/banjun/Caerula'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'banjun' => 'banjun@gmail.com' }
  s.source           = { :git => 'https://github.com/banjun/Caerula.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/banjun'
  s.ios.deployment_target = '9.0'
  s.source_files = 'Caerula/Classes/**/*'
  s.frameworks = 'UIKit', 'CoreLocation'
  s.dependency 'NorthLayout', '~> 5.0'
  s.dependency '※ikemen'
end
