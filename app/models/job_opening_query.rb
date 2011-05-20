class JobOpeningQuery
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  def persisted?; false; end

  attr_accessor :attributes
  def initialize(attrs = {})
    @attributes = (attrs || {}).with_indifferent_access
  end
  
  def job_categories
    attributes[:job_categories] || ""
  end

  def job_categories_codes
    @job_categories_codes ||= job_categories.split(";")
  end

  def job_categories_names
    return @job_categories_names if defined? @job_categories_names
    return @job_categories_names = I18n.t("all") if job_categories_codes.blank?
    return @job_categories_names = job_categories_codes.map { |code| I18n.t("isco_code.#{code}") }.join("; ")
  end

  def locations
    attributes[:locations] || ""
  end

  def locations_geonameids
    @locations_geonameids ||= locations.split(";").map { |loc| loc.split(":").last.to_i }
  end

  def locations_names
    return @locations_names if defined? @locations_names
    return @locations_names = I18n.t("all") if locations_geonameids.blank?
    return @locations_names = locations_geonameids.map { |geonameid| 
      loc = GeonamesLocation.where(geonameid: geonameid).first
      loc.is_pcl ? I18n.t("iso_3166_1_alpha_2.#{loc.country_code}") : loc.name 
    }.join("; ")
  end

  def locations_query_hash
    locs = { 
      pcls: [], 
      admin1s: [],
      admin2s: []
    }
    if locations.present? 
      locations.split(";").each { |loc|   
        type, geonameid = loc.split(":")
        case type
        when "PCL"; locs[:pcls] << geonameid
        when "ADM1"; locs[:admin1s] << geonameid
        when "ADM2"; locs[:admin2s] << geonameid
        else raise type
        end
      }
    end
    return locs
  end
  
end
