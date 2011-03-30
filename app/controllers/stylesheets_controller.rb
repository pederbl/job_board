class StylesheetsController < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Helpers
  include AbstractController::AssetPaths
  include ActionController::UrlWriter

  helper ApplicationHelper

  self.view_paths = File.join(Rails.root, 'app', 'views')

  stylesheets = Dir.glob("#{Rails.root}/app/views/stylesheets/*.css.erb").entries.map { |path| File.basename(path).gsub(/.css.erb$/, '') }
  
  stylesheets.each { |name|
    define_method name do 
      render name 
    end
  }
end
