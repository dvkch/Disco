Pod::Spec.new do |s|
  s.ios.deployment_target  = '12.0'
  s.osx.deployment_target  = '10.14'
  s.name     = 'Disco'
  s.version  = '1.0.0'
  s.license  = { :type => 'Custom' }
  s.summary  = 'Network library for hosts discovery and monitoring'
  s.homepage = 'https://github.com/dvkch/Disco'
  s.author   = { 'Stan Chevallier' => 'contact@stanislaschevallier.fr' }
  s.source   = { :git => 'https://github.com/dvkch/Disco.git', :tag => s.version.to_s }
  s.swift_version = '5.8'
  
  s.source_files = 'Disco/*.swift'
  s.dependency 'SwiftyPing', '>= 1.2.2'

  s.xcconfig = { 'CLANG_MODULES_AUTOLINK' => 'YES' }
end
