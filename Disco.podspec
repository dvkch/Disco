Pod::Spec.new do |s|
  s.ios.deployment_target  = '12.0'
  s.name     = 'Disco'
  s.version  = '1.0.0'
  s.license  = { :type => 'Custom' }
  s.summary  = 'SANE backends, net only'
  s.homepage = 'https://github.com/dvkch/Disco'
  s.author   = { 'Stan Chevallier' => 'contact@stanislaschevallier.fr' }
  s.source   = { :git => 'https://github.com/dvkch/Disco.git', :tag => s.version.to_s }
  s.swift_version = '5.0'
  
  s.source_files = 'Disco/*.swift'
  s.dependency 'GBPing', '~> 1.5'

  s.requires_arc = true
  s.xcconfig = { 'CLANG_MODULES_AUTOLINK' => 'YES' }
end
