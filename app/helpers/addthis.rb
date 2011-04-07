module Addthis
  
  class Client
    def self.fetch_most_shared_jobs
      result = RestClient.get "https://pederbl:hej3hopp@api.addthis.com/analytics/1.0/pub/shares/url.json?period=week", {:accept => :json}
      ActiveSupport::JSON.decode(result).each { |hash| 
        shares = hash["shares"]
        url = hash["url"]
        next unless url =~ /^http:\/\/jobboteket.se\/jobb\//
        job_slug = url.scan(/[^\/]*$/).first
        job = JobOpening.where(slug: job_slug).first
        next if job.deleted_at
        puts job.id
      }
      nil
    end
  end

end

