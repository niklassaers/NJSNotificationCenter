Pod::Spec.new do |s|

  s.name         = "NJSNotificationCenter"
  s.version      = "0.0.1"
  s.summary      = "An NSNotificationCenter replacement reducing boilerplate around threads and execution ordering"

  s.description  = <<-DESC
                   A longer description of NJSNotificationCenter in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/niklassaers/NJSNotificationCenter"

  s.license      = { :type => 'BSD', :file => 'LICENSE' }


  s.author       = { "Niklas Saers" => "niklas@saers.com" }


  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/niklassaers/NJSNotificationCenter.git", :commit => "a002f651ba0366d98b375bef8b5a27dc5c9fece0" }


  s.source_files  = 'NJSNotificationCenter/*.{h,m}'

  # s.public_header_files = 'NJSNotificationCenter/*.h'

  s.requires_arc = true

end


