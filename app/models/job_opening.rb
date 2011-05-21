require JobOpeningModels::JobOpeningModelsEngine.root.join("app", "models", "job_opening")
class JobOpening
  #BASE_URL = "http://ec2-46-137-5-1.eu-west-1.compute.amazonaws.com"
  include Mongoid::Document
  include Mongoid::TranslatedStrings

  field :sphinx_id, type: Integer

  index :slug, unique: true
  index :deleted_at
  index "salary.normalized_salary"
  index :publish_at
  index :sphinx_id, unique: true

  def set_geonameid
    return if location.nil?
    arr = [] 
    arr << "country_code=#{location.country}"
    arr << "admin1=#{location.region}" if location.region
    arr << "admin2=#{location.city}" if location.city
    query = arr.join("&")

    require 'open-uri'
    geonameid = open("http://ec2-46-137-107-116.eu-west-1.compute.amazonaws.com/geonames_locations/search?#{query}") { |f|  
      ActiveSupport::JSON.decode(f.read).first["geonameid"] 
    }.inspect   
    update_attribute("location.geonameid", geonameid)
  end

  def geonames_location
    GeonamesLocation.where(geonameid: location.geonameid).first
  end

  def search_same_employer
    return nil unless employer
    JobOpening.search(JobOpeningQuery.new(employer: employer.name, limit: 5))
  end

  def search_same_location
    return nil unless location.try(:geonameid)
    JobOpening.search(JobOpeningQuery.new(locations: "#{geonames_location.feature_code}:#{location.geonameid}", limit: 5)) 
  end

  def search_same_job_category
    return nil unless isco
    JobOpening.search(JobOpeningQuery.new(job_categories: isco.to_s, limit: 5))
  end

  def self.num_active
    where(deleted_at: nil).count
  end

  def self.search(job_opening_query)
    q = job_opening_query
    attrs = {
      keywords: q.keywords, 
      employer: q.employer,
      locations: q.locations_query_hash,
      job_categories: q.job_categories_codes,
      limit: q.attributes[:limit] || 10,
      max_id: q.attributes[:max_id].try(:to_i),
      sort_by: "@id DESC",
      sort_mode: :extended,
      match_mode: :extended
    }

    arr = []
    arr << "@(title,body) #{Riddle.escape(wrap_wildcards(attrs[:keywords]))}" if attrs[:keywords].present?
    arr << "@(employer) #{Riddle.escape(wrap_wildcards(attrs[:employer]))}" if attrs[:employer].present?
    arr << "@(isco_code) (#{attrs[:job_categories].map { |code| code + "*" }.join(" | ")})" if attrs[:job_categories].present?

    loc_arr = []
    loc_arr << "@(pcl_geonameid) (#{attrs[:locations][:pcls].join(" | ")})" if attrs[:locations][:pcls].present?
    loc_arr << "@(admin1_geonameid) (#{attrs[:locations][:admin1s].join(" | ")})" if attrs[:locations][:admin1s].present?
    loc_arr << "@(admin2_geonameid) (#{attrs[:locations][:admin2s].join(" | ")})" if attrs[:locations][:admin2s].present?
    arr << "(#{loc_arr.join(" | ")})" if loc_arr.present?

    query = arr.join(" ")
    client = Riddle::Client.new 
    client.sort_mode = attrs[:sort_mode]
    client.sort_by = attrs[:sort_by]
    client.match_mode = attrs[:match_mode]
    client.limit = attrs[:limit]
    client.filters << Riddle::Client::Filter.new("deleted_at", [0])
    client.id_range = 0..(attrs[:max_id]) if attrs[:max_id]
    results = client.query(query, "job_openings,job_openings_delta")
    
    raise results[:error].inspect if results[:error].present?
    return results
  end

  def self.reindex_main
    system("cd /home/ec2-user/sphinx-1.10-beta; sudo /usr/local/bin/indexer job_openings --rotate >> /home/ec2-user/log/indexer_main.log 2>&1")
    puts "old delta_min_id: #{delta_min_id}"
    self.delta_min_id = main_max_id + 1
    puts "new delta_min_id: #{delta_min_id}"
  end
  
  def self.reindex_delta
    puts "delta_min_id: #{delta_min_id}"
    set_sphinx_ids
    system("cd /home/ec2-user/sphinx-1.10-beta; sudo /usr/local/bin/indexer job_openings_delta --rotate >> /home/ec2-user/log/indexer_delta.log 2>&1")
  end

  def self.main_xmlpipe_feed
    job_openings = JobOpening.where(
      deleted_at: nil, 
      :sphinx_id.ne => nil, 
      :sphinx_id.lt => next_id # exclude ids of crashed set_sphinx_ids
    ).desc(:sphinx_id) 
    self.main_max_id = job_openings.first.sphinx_id if job_openings.count > 0
    create_job_openings_feed(job_openings.map(&:id))
  end

  def self.delta_xmlpipe_feed
    # "- 1" bug workaround "fullscan requires extern docinfo" on empty indexes
    job_openings = JobOpening.where(deleted_at: nil, :sphinx_id.ne => nil, :sphinx_id.gte => delta_min_id - 1).desc(:sphinx_id) 
    create_job_openings_feed(job_openings.map(&:id))
  end


  private

  DELTA_MIN_ID = "sphinx_job_openings_delta_min_id"
  def self.delta_min_id
    Value.get(DELTA_MIN_ID) || 1
  end
  
  def self.delta_min_id=(val)
    Value.set(DELTA_MIN_ID, val)
  end

  MAIN_MAX_ID = "sphinx_job_openings_main_max_id"
  def self.main_max_id
    Value.get(MAIN_MAX_ID) || 0
  end

  def self.main_max_id=(val)
    Value.set(MAIN_MAX_ID, val)
  end

  NEXT_ID = "sphinx_job_openings_next_id"
  def self.next_id
    Value.get(NEXT_ID) || 1
  end

  def self.next_id=(val)
    Value.set(NEXT_ID, val)
  end
  
  def self.set_sphinx_ids
    last_id = next_id - 1
    jobs = JobOpening.where(deleted_at: nil).any_of({sphinx_id: nil}, {:sphinx_id.gt => last_id}).asc(:publish_at)
    puts jobs.count.inspect
    jobs.each { |d| 
      puts last_id.inspect if last_id.modulo(1000) == 0 
      d.update_attribute(:sphinx_id, last_id += 1) 
    }
    self.next_id = last_id + 1
  end
  
  def self.create_job_openings_feed(ids)
    xml = ::Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)
    xml.instruct!
    xml.sphinx:docset do |docset| 
      xml.sphinx:schema do |schema|
        schema.send("sphinx:field", name: "title", attr: "string")
        schema.send("sphinx:field", name: "body")
        schema.send("sphinx:field", name: "employer", attr: "string")
        schema.send("sphinx:field", name: "isco_code", attr: "string")
        schema.send("sphinx:field", name: "salary_currency", attr: "string")
        schema.send("sphinx:field", name: "salary_period", attr: "string")
        schema.send("sphinx:field", name: "country_code", attr: "string")
        schema.send("sphinx:field", name: "pcl_geonameid", attr: "string")
        schema.send("sphinx:field", name: "admin1_geonameid", attr: "string")
        schema.send("sphinx:field", name: "admin2_geonameid", attr: "string")

        #deprecated
        schema.send("sphinx:field", name: "country", attr: "string")
        schema.send("sphinx:field", name: "region", attr: "string")
        schema.send("sphinx:field", name: "city", attr: "string")
        schema.send("sphinx:field", name: "isco", attr: "string")

        schema.send("sphinx:attr", name: "_id", type: "string")
        schema.send("sphinx:attr", name: "slug", type: "string")
        schema.send("sphinx:attr", name: "publish_at", type: "timestamp")
        schema.send("sphinx:attr", name: "deleted_at", type: "timestamp")
        schema.send("sphinx:attr", name: "normalized_salary", type: "float")
        schema.send("sphinx:attr", name: "minimum_salary", type: "float")
        schema.send("sphinx:attr", name: "worktime", type: "string")
        schema.send("sphinx:attr", name: "duration", type: "string")
        schema.send("sphinx:attr", name: "hours_per_week", type: "float")
      end
      
      prev_id = nil
      ids.each { |id|
        d = JobOpening.find(id)
        next if d.deleted_at
        raise "no sphinx_id" if d.sphinx_id.nil?
        raise d.sphinx_id.inspect if prev_id.present? and prev_id <= d.sphinx_id 
        prev_id = d.sphinx_id
        docset.send("sphinx:document", id: d.sphinx_id) do |doc|
          doc.title(d.t(:title))
          doc.body(d.t(:body))
          doc.employer(d.employer.try(:name))
          doc.salary_currency(d.salary.try(:currency))
          doc.salary_period(d.salary.try(:period))
          doc.isco_code(d.isco.to_s.split(".").first.gsub(/0+$/, "")) if d.isco.present?

          geoname_location = GeonamesLocation.where(geonameid: d.location.geonameid).first if d.location
          if geoname_location
            doc.country_code(geoname_location.country_code)
            doc.pcl_geonameid(geoname_location.pcl_geonameid)
            doc.admin1_geonameid(geoname_location.admin1_geonameid)
            doc.admin2_geonameid(geoname_location.admin2_geonameid)
          end

          doc._id(id)
          doc.slug(d.slug)
          doc.publish_at(d.publish_at.to_i)
          doc.normalized_salary(d.salary.normalized) if d.salary.try(:normalized)
          doc.minimum_salary(d.salary.minimum) if d.salary.try(:minimum)
          doc.worktime(d.worktime.type) if d.worktime.try(:type)
          doc.duration(d.duration.length) if d.duration.try(:length)
          doc.hours_per_week(d.worktime.hours_per_week) if d.worktime.try(:hours_per_week)

          # deprecated
          doc.country(I18n.t("iso_3166_1_alpha_2.#{d.location.country}").titleize) if d.location.try(:country).present?
          doc.region(d.location.try(:region))
          doc.city(d.location.try(:city))

          if d.isco
            isco = d.isco.to_s.split(".").first.gsub(/0+$/, "")
            begin
              translation = I18n.t("isco_code.#{isco}", default: "MISSING")
              if translation == "MISSING" or translation.nil? 
                raise(I18n::MissingTranslationData.new(I18n.locale, isco, {})) 
              end
            rescue I18n::MissingTranslationData
              if isco.length > 2
                isco.gsub!(/.$/, "") 
                retry
              else 
                isco = nil
              end
            end
            doc.isco(I18n.t("isco_code.#{isco}").singularize) if isco.present?
          end
        end
      }
    end
    xml.target! 
  end

  private

  def self.wrap_wildcards(s)
    s.split(" ").map { |word| "*#{word}*" }.join(" ")
  end

end
