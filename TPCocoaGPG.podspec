Pod::Spec.new do |spec|
  spec.name                    = 'TPCocoaGPG'
  spec.version                 = '0.1.5'
  spec.license                 = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage                = 'https://github.com/pelletier/TPCocoaGPG'
  spec.authors                 = { 'Thomas Pelletier' => 'pelletier.thomas@gmail.com' }
  spec.summary                 = 'OpenGPG wrapper for Cocoa'
  spec.source                  = { :git => 'https://github.com/pelletier/TPCocoaGPG.git', :tag => "v#{spec.version}" }
  spec.osx.platform            = :osx, '10.9'
  spec.osx.deployment_target   = '10.9'
  spec.osx.source_files        = 'TPCocoaGPG/*.{h,m}'
  spec.osx.public_header_files = 'TPCocoaGPG/*.h'
end
