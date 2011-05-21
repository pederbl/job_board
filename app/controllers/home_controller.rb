class HomeController < ApplicationController
  helper :job_openings
  
  def index
    ids = Value.get("most_shared_jobs").map { |h| h["id"] }[0..4]
    @most_shared_jobs = JobOpening.where(:_id.in => ids).sort { |x, y| ids.index(x.id) <=> ids.index(y.id) }

    ids = Value.get("highest_paid_jobs")[0..4]
    @highest_paid_jobs = JobOpening.where(:_id.in => ids).sort { |x, y| ids.index(x.id) <=> ids.index(y.id) }
  end

end
