class JobOpeningsController < ApplicationController
  respond_to :html, :js, :json

  def index
    @query = JobOpeningQuery.new(params[:q])
    @result = JobOpening.search(@query)
  end

  def show
    @job = JobOpening.where(slug: params[:id]).first
    raise "not found" if !@job and Rails.env.development? 
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

  def apply
    @job = JobOpening.where(slug: params[:id]).first
  end


  def more 
    @query = JobOpeningQuery.new(params[:q])
    @result = JobOpening.search(@query)
  end

  def job_categories_picker_node_children
    @query = JobOpeningQuery.new(params[:q])
    children = Isco::children[params[:key]]
    children.map! { |code|
      { 
        title: I18n.t("isco_code.#{code}"),
        isLazy: Isco::children[code].present?, 
        key: code,
        select: @query.job_categories_codes.include?(code)
      }
    }
    children.sort! { |x, y| x[:title] <=> y[:title] }
    render json: children
  end

  def locations_picker_node_children
    @query = JobOpeningQuery.new(params[:q])
    geoname_location = GeonamesLocation.where(geonameid: params[:key].split(":").last).first
    children = geoname_location.children
    children.map! { |d| 
      { 
        title: d.name, 
        isLazy: d.has_children, 
        key: "#{d.feature_code}:#{d.geonameid}",
        select: @query.locations_geonameids.include?(d.geonameid)
      } 
    } 
    children.sort! { |x, y| x[:title] <=> y[:title] } 
    render json: children
  end

end
