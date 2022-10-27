Pod::Spec.new do |s|
   s.name                   = 'Evergreen'
   s.module_name            = 'Evergreen'
   s.version                = '0.0.8'
   s.summary                = 'Swift package to manage Evergreen Markdown'
   s.homepage               = 'https://github.com/bhaze31/evergreen-swift'
   s.author                 = { 'Brian Hasenstab' => 'brian.hasenstab31@gmail.com' }
   s.source                 = { :git => 'https://github.com/bhaze31/evergreen-swift.git', :tag => s.version }
   s.osx.deployment_target = '10.15'
   s.requires_arc = true
   s.swift_version = '5.2'
   s.source_files = 'Sources/Evergreen/**/*.{swift}'
 end
