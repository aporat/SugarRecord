Pod::Spec.new do |s|
  s.name             = "SugarRecord"
  s.version          = "5.0.0"
  s.summary          = "CoreData wrapper written on Swift"
  s.homepage         = "https://github.com/carambalabs/SugarRecord"
  s.license          = 'MIT'
  s.author           = { "Pedro" => "pepibumur@gmail.com" }
  s.source           = { :git => "https://github.com/carambalabs/SugarRecord.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/carambalabs'
  s.requires_arc = true

  s.ios.deployment_target = "12.0"

end
