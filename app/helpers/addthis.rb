module Addthis
  
  class Client
    def self.sync_most_shared_jobs
      result = RestClient.get "https://pederbl:hej3hopp@api.addthis.com/analytics/1.0/pub/shares/url.json?period=week", {:accept => :json}
      list = []
      ActiveSupport::JSON.decode(result).each { |hash| 
        num = hash["shares"]
        url = hash["url"]
        puts [url, num].inspect
        next unless url =~ /^http:\/\/jobboteket.se\/jobb\//
        job_slug = url.scan(/[^\/]*$/).first
        job = JobOpening.where(slug: job_slug).first
        next if job.deleted_at
        list << { id: job.id, num: num }
        break if list.length == 10
      }
      Value.set("most_shared_jobs", list) 
    end
  end

end

