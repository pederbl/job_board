class HomeController < ApplicationController
  helper :job_openings
  
  def index
    ids = Value.get("most_shared_jobs").map { |h| h["id"] }
    @most_shared_jobs = JobOpening.where(:_id.in => ids).sort { |x, y| ids.index(x.id) <=> ids.index(y.id) }[0..4]

    ids = Value.get("highest_paid_jobs")
    @highest_paid_jobs = JobOpening.where(:_id.in => ids).sort { |x, y| ids.index(x.id) <=> ids.index(y.id) }[0..4]

    @num_jobs = JobOpening.where(deleted_at: nil).count
  end


end
