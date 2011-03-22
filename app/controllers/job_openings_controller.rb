class JobOpeningsController < ApplicationController

  respond_to :html, :json

  def index
    @job_openings = JobOpening.where(deleted_at: nil).limit(10)
  end

  def show
    @job_opening = JobOpening.where(slug: params[:id]).first
  end

  def create
    attrs = params[:job_opening]
    @job_opening = JobOpening.where(source: attrs[:source], source_id: attrs[:source_id]).first
    if @job_opening
      @job_opening.update_attributes(attrs)
    else
      @job_opening = JobOpening.create(attrs)
    end
    if @job_opening.valid?
      render json: { status: 1 } 
    else
      logger.info(@job_opening.errors.inspect)
      render json: { status: 0, error: @job_opening.errors }, status: 500
    end
  end

  def update 
  end

end
