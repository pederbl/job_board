module ApplicationHelper

  def all_javascripts
    javascript_names = Dir.glob("#{Rails.root}/app/views/javascripts/*.js.erb").entries.map { |path| File.basename(path).gsub(/.js.erb$/, '') }

    to_delete = Dir.glob("#{Rails.root}/public/javascripts/auto_generated/*").entries.map { |path| File.basename(path).gsub(/.js$/, '') } - javascript_names
    to_delete.each { |name| File.delete("#{Rails.root}/public/javascripts/auto_generated/#{name}.js") }

    javascript_names.each { |name|
      path_auto_generated = "#{Rails.root}/public/javascripts/auto_generated/#{name}.js"
      File.open("#{Rails.root}/public/javascripts/auto_generated/#{name}.js", "w") { |f| 
        f.write("/* #{name} */\n")
        f.write(JavascriptsController.new.send(name)) 
      }
    }
    (
      ['/javascripts/jquery/js/jquery-1.4.4.min.js', '/javascripts/jquery/js/jquery-ui-1.8.11.custom.min.js', '/javascripts/prio/rails.js'] +
      Dir.glob("#{Rails.root}/public/javascripts/*.js").entries.map { |path| File.basename(path).gsub(/.js$/,'') } +
      Dir.glob("#{Rails.root}/public/javascripts/auto_generated/*.js").map { |path| 'auto_generated/' + File.basename(path).gsub(/.js$/,'') }
    )
  end

  def all_stylesheets
    stylesheet_names = Dir.glob("#{Rails.root}/app/views/stylesheets/*.css.erb").entries.map { |path| File.basename(path).gsub(/.css.erb$/, '') }
     
    to_delete = Dir.glob("#{Rails.root}/public/stylesheets/auto_generated/*").entries.map { |path| File.basename(path).gsub(/.css$/, '') } - stylesheet_names
    to_delete.each { |name| File.delete("#{Rails.root}/public/stylesheets/auto_generated/#{name}.css") }

    stylesheet_names.each { |name|
      path_auto_generated = "#{Rails.root}/public/stylesheets/auto_generated/#{name}.css"
      File.open("#{Rails.root}/public/stylesheets/auto_generated/#{name}.css", "w") { |f| 
        f.write("/* #{name} */\n")
        f.write(StylesheetsController.new.send(name)) 
      }
    }
    (
      Dir.glob("#{Rails.root}/public/stylesheets/*.css").entries.map { |path| File.basename(path).gsub(/.css$/,'') }  +
      Dir.glob("#{Rails.root}/public/stylesheets/auto_generated/*.css").map { |path| 'auto_generated/' + File.basename(path).gsub(/.css$/,'') }  + 
      ['/javascripts/jquery/css/smoothness/jquery-ui-1.8.11.custom.css']
    )
  end

  def bot?
    return @bot if defined? @bot
    bot_regex = /(peder|bot|crawler|spider| agent|xx|Mediapartners-Google|slurp|ia_archiver|majestic|yandex|pingdom|mAgent|R \(2\.8\.1\)|Ask Jeeves|ScoutJet)/i 
    @bot = (request.user_agent and request.user_agent =~ bot_regex)
  end

end
