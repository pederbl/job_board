class JavascriptsController < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Helpers
  include AbstractController::AssetPaths
  include ActionController::UrlWriter

  helper ApplicationHelper

  self.view_paths = File.join(Rails.root, 'app', 'views')

  javascripts = Dir.glob("#{Rails.root}/app/views/javascripts/*.js.erb").entries.map { |path| File.basename(path).gsub(/.js.erb$/, '') }
  
  javascripts.each { |name|
    define_method name do 
      render name 
    end
  }
end
