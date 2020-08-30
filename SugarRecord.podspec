Pod::Spec.new do |s|
  s.name             = "SugarRecord"
  s.version          = "5.0.0"
  s.summary          = "CoreData wrapper written on Swift"
  s.homepage         = "https://github.com/carambalabs/SugarRecord"
  s.license          = 'MIT'
  s.author           = { "Pedro" => "pepibumur@gmail.com" }
  s.social_media_url = 'https://twitter.com/carambalabs'
  s.requires_arc = true
  s.platform                  = :ios, '12.0'
  s.ios.deployment_target     = '12.0'
  s.requires_arc              = true
  s.source                    = { :git => 'https://github.com/aporat/SugarRecord.git', :tag => s.version.to_s }
  s.source_files              = 'SugarRecord/*.{swift}'
  s.swift_version             = '5.0'


end
