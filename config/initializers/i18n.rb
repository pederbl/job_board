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
