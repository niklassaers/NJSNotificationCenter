Pod::Spec.new do |s|

  s.name         = "NJSNotificationCenter"
  s.version      = "1.0"
  s.summary      = "An NSNotificationCenter replacement reducing boilerplate around threads and execution ordering"

  s.description  = <<-DESC
                   NJSNotificationCenter replaces NSNotificationCenter to help you
                   reduce boilerplate around threads and execution ordering,
                   and allows you to make notifications async very easily
                   DESC

  s.homepage     = "https://github.com/niklassaers/NJSNotificationCenter"

  s.license      = { :type => 'BSD', :file => 'LICENSE' }


  s.author       = { "Niklas Saers" => "niklas@saers.com" }


  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/niklassaers/NJSNotificationCenter.git", :tag => 'v1.0' }


  s.source_files  = 'NJSNotificationCenter/*.{h,m}'

  # s.public_header_files = 'NJSNotificationCenter/*.h'

  s.requires_arc = true

end


