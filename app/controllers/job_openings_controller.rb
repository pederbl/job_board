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

  def location_picker_node_children
    geoname_location = GeonamesLocation.where(geonameid: params[:key].split(":").last).first
    children = geoname_location.children
    children.map! { |d| { title: d.name, isLazy: d.has_children, key: "#{d.feature_code}:#{d.geonameid}" } } 
    children.sort! { |x, y| x[:title] <=> y[:title] } 
    render json: children
  end

  private 

  def query
    q = params[:q] || {}
    return JobOpening.search(
      keywords: q[:keywords], 
      employer: q[:employer],
      locations: q[:locations],
      limit: q[:num] || 10,
      from_id: q[:from_id].try(:to_i)
    )
  end

end
