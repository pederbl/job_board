class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_locale
  def set_locale
    cookies[:locale] = I18n.preferred_locale(request.env['HTTP_ACCEPT_LANGUAGE']) || I18n.default_locale unless cookies[:locale]
    I18n.locale = cookies[:locale] 
  end

end
