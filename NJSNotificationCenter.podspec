Pod::Spec.new do |s|
  s.name     = 'NJSNotificationCenter'
  s.version  = '1.0'
  s.license  = :type => 'BSD'
  s.summary  = 'An NSNotificationCenter replacement reducing boilerplate around threads and execution ordering'
  s.homepage = 'https://github.com/niklassaers/NJSNotificationCenter'
  s.author   = 'Niklas Saers' => 'niklas@saers.com'
  s.source   = { :git => 'https://github.com/niklassaers/NJSNotificationCenter.git' }
  s.osx.source_files = 'NJSNotificationCenter/*.{h,m}'
  s.ios.source_files = 'NJSNotificationCenter/*.{h,m}'
	s.requires_arc = true
end
