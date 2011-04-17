class JobOpeningsController < ApplicationController

  respond_to :html, :js, :json

  def index
    @result = query
  end

  def show
    @job = JobOpening.where(slug: params[:id]).first
    return redirect_to("/", status: 301) unless @job
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

  def more 
    @result = query
  end

  private 

  def query
    return JobOpening.search(
      keywords: params[:keywords], 
      employer: params[:employer],
      location: params[:location],
      limit: params[:num] || 10,
      from_id: params[:from_id].try(:to_i)
    )
  end

end
