class Sphinx < Thor

  require File.expand_path('config/environment.rb') 

  desc "index_job_openings_main", "run indexer for main index of job_openings"
  def index_job_openings_main
    JobOpening.reindex_main
  end
  
  desc "index_job_openings_delta", "run indexer for delta index of job_openings"
  def index_job_openings_delta
    JobOpening.reindex_delta
  end

  desc "job_openings", "output xmlpipe for job openings"
  def job_openings
    JobOpening.main_xmlpipe_feed
  end

  desc "job_openings_delta", "output xmlpipe for job openings delta"
  def job_openings_delta
    JobOpening.delta_xmlpipe_feed
  end

  desc "geonames_locations", "output xmlpipe for geonames_locations"
  def geonames_locations
    GeonamesLocation.xmlpipe_main
  end
  
end
