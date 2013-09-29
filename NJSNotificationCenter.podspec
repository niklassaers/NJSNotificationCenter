Pod::Spec.new do |s|
  s.name     = 'NJSNotificationCenter'
  s.version  = '1.0'
  s.license  = 'BSD 2-clause'
  s.summary  = 'An NSNotificationCenter replacement reducing boilerplate around threads and execution ordering'
  s.homepage = 'https://github.com/niklassaers/NJSNotificationCenter'
  s.author   = { 'Niklas Saers' => 'niklas@saers.com' }
  s.source   = { :git => 'https://github.com/niklassaers/NJSNotificationCenter.git', :tag => 'v1.0' }
  s.osx.source_files = 'NJSNotificationCenter/*.{h,m}'
  s.ios.source_files = 'NJSNotificationCenter/*.{h,m}'
  s.documentation = {
    :html => 'http://niklassaers.github.com/NJSNotificationCenter/Documentation/index.html',
    :appledoc => [
      '--project-company', 'SAERS',
      '--company-id', 'com.saers',
      '--no-repeat-first-par',
      '--no-warn-invalid-crossref'
    ]
  }
end
