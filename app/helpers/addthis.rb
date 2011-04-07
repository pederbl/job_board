module Addthis
  
  class Client
    def self.fetch_most_shared_jobs
      result = RestClient.get "https://pederbl:hej3hopp@api.addthis.com/analytics/1.0/pub/shares/url.json?period=week", {:accept => :json}
      ActiveSupport::JSON.decode(result).each { |url| puts url.inspect }
    end
  end

end

