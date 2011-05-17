class GeonamesLocationsController < ApplicationController

  respond_to :json

  def show
    @geonames_location = GeonamesLocation.where(geonameid: params[:id]).first
    render json: @geonames_location
  end

  def search
    @geonames_locations = GeonamesLocation.search(
      country: params[:country], 
      country_code: params[:country_code],
      admin1: params[:admin1],
      admin2: params[:admin2]
    )
    render json: @geonames_locations
  end

end
