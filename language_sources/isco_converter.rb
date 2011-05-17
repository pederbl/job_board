require "../config/environment.rb"


language_codes = %w{bg cs da de el en es et fi fr ga hu is it lt lv mt nl no pl pt ro sk sl sv }
language_codes = ARGV if ARGV.first
language_codes.each { |language_code|
  puts language_code
  isco = []
  File.open("isco_#{language_code}") { |f| eval f.read }
  isco = isco.inject({}) { |hash, v| code, str = v.split(" ^ "); hash[code] = str; hash } 
  YAML::dump({ language_code => { "isco_code" => isco } }, File.open("../config/locales/#{language_code}.isco.yml", "w"))
}
