I18n.default_locale = :en

module I18n
  
  def self.name_for_locale(locale = nil)
    I18n.backend.translate(locale || I18n.locale, "i18n.language.name")
  rescue I18n::MissingTranslationData
    locale.to_s
  end 

  def self.preferred_locale(http_accept_language)
    arr = http_accept_language.try(:split, /\s*,\s*/)
    arr.reject! { |l| !(l =~ /^[a-z\-]+(;q=[0-9]*\.?[0-9]+)?$/i) } if arr.present?
    return nil unless arr.present? 

    arr.map! { |l| 
      lang, prio = l.split(';q=') 
      prio ||= 1.0
      [lang, prio.to_f]
    }
    arr.sort! { |x, y| y.last <=> x.last }
    arr.map! { |l| l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }.to_sym }
    return arr.find { |l| available_locales.include?(l) } || 
           arr.find { |l| available_locales.include?(l.gsub(/-../, "")) } 
  end


end


if Rails.env.production?
  module I18n
    def self.just_raise_that_exception(*args)
      raise args.first
    end
  end
  
  I18n.exception_handler = :just_raise_that_exception 
  
  module ActionView
    module Helpers
      module TranslationHelper
        def t(key, options = {})
          options[:raise] = true
          I18n.translate(scope_key_by_partial(key), options)
        end
      end
    end
  end
end
