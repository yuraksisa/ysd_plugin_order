Gem::Specification.new do |s|
  s.name    = "ysd_plugin_order"
  s.version = "0.2.47"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2014-10-06"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb','views/**/*.erb','i18n/**/*.yml','static/**/*.*'] 
  s.description = "Order plugin"
  s.summary = "Order plugin"
  
  s.add_runtime_dependency "json"
  
  s.add_runtime_dependency "ysd_core_plugins"
  s.add_runtime_dependency "ysd_core_themes"
  s.add_runtime_dependency "ysd_yito_core"
  s.add_runtime_dependency "ysd_yito_js"

  s.add_runtime_dependency "ysd_md_order"
  s.add_runtime_dependency "ysd_plugin_auth"

  s.add_development_dependency "dm-sqlite-adapter" # Model testing using sqlite
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "sinatra-r18n"

end
