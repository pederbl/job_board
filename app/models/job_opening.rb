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
  index :sphinx_id

  def self.search(attrs)
    attrs = {
      limit: 10,
      sort_by: "publish_at",
      sort_mode: :attr_desc,
      match_mode: :extended
    }.merge(attrs)

    arr = []
    arr << "@(title,body) #{Riddle.escape(wrap_wildcards(attrs[:keywords]))}" if attrs[:keywords].present?
    arr << "@(employer) #{Riddle.escape(wrap_wildcards(attrs[:employer]))}" if attrs[:employer].present?
    arr << "@(country,region,city) #{Riddle.escape(wrap_wildcards(attrs[:location]))}" if attrs[:location].present?
    query = arr.compact.join(" ")

    client = Riddle::Client.new 
    client.sort_mode = attrs[:sort_mode]
    client.sort_by = attrs[:sort_by]
    client.match_mode = attrs[:match_mode]
    client.limit = attrs[:limit]
    client.filters << Riddle::Client::Filter.new("deleted_at", [0])
    client.id_range = (attrs[:from_id] + 1)..0 if attrs[:from_id]
    results = client.query(query)
  end

  def self.reindex_main
    system("cd /home/ec2-user/sphinx-1.10-beta; sudo /usr/local/bin/indexer job_openings --rotate")
    main_max_id = Value.get("sphinx_job_openings_main_max_id")
    Value.set("sphinx_job_openings_delta_min_id", main_max_id + 1)
  end
  
  def self.reindex_delta
    system("cd /home/ec2-user/sphinx-1.10-beta; sudo /usr/local/bin/indexer job_openings_delta --rotate")
  end

  def self.main_xmlpipe_feed
    next_id = (Value.get("sphinx_job_openings_next_id") || 1)
    ids = JobOpening.where(deleted_at: nil, :sphinx_id.ne => nil, :sphinx_id.lt => next_id).desc(:sphinx_id).map(&:id) #exclude ids of crashed delta indexing
    Value.set("sphinx_job_openings_main_max_id", ids.first || 0)
    create_job_openings_feed(ids)
  end

  def self.delta_xmlpipe_feed
    delta_min_id = Value.get("sphinx_job_openings_delta_min_id") || 1
    original_last_id = last_id = (Value.get("sphinx_job_openings_next_id") || 1) - 1
    ids = JobOpening.where(deleted_at: nil).any_of({ sphinx_id: nil }, { :sphinx_id.gte => delta_min_id }).desc(:publish_at).map { |d| 
      d.update_attribute(:sphinx_id, last_id += 1) if (d.sphinx_id.nil? or d.sphinx_id > original_last_id) # must reset ids if this process crashed
      d.id
    }
    Value.set("sphinx_job_openings_next_id", last_id + 1)
    create_job_openings_feed(ids)
  end

  private

  def self.create_job_openings_feed(ids)
    xml = Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)
    xml.instruct!
    xml.sphinx:docset do |docset| 
      xml.sphinx:schema do |schema|
        schema.send("sphinx:field", name: "title", attr: "string")
        schema.send("sphinx:field", name: "body")
        schema.send("sphinx:field", name: "employer", attr: "string")
        schema.send("sphinx:field", name: "country", attr: "string")
        schema.send("sphinx:field", name: "region", attr: "string")
        schema.send("sphinx:field", name: "city", attr: "string")
        schema.send("sphinx:field", name: "salary_currency", attr: "string")
        schema.send("sphinx:field", name: "salary_period", attr: "string")
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

      ids.each { |id|
        d = JobOpening.find(id)
        next if d.deleted_at
        raise "no sphinx_id" if d.sphinx_id.nil?
        docset.send("sphinx:document", id: d.sphinx_id) do |doc|
          doc.title(d.t(:title))
          doc.body(d.t(:body))
          doc.employer(d.employer.try(:name))
          doc.country(I18n.t("iso_3166_1_alpha_2.#{d.location.country}").titleize) if d.location.try(:country)
          doc.region(d.location.try(:region))
          doc.city(d.location.try(:city))
          doc.salary_currency(d.salary.try(:currency))
          doc.salary_period(d.salary.try(:period))

          if d.isco
            isco = d.isco.to_s.split(".").first.gsub(/0+$/, "")
            translation = nil
            while translation.nil?
              translation = I18n.t("isco_code.#{isco}", default: "MISSING")
              translation = nil if translation == "MISSING"
              isco.gsub!(/.$/, "") if translation.nil?
            end
            doc.isco(I18n.t("isco_code.#{isco}").singularize) if isco.present?
          end

          doc._id(id)
          doc.slug(d.slug)
          doc.publish_at(d.publish_at.to_i)
          doc.normalized_salary(d.salary.normalized) if d.salary.try(:normalized)
          doc.minimum_salary(d.salary.minimum) if d.salary.try(:minimum)
          doc.worktime(d.worktime.type) if d.worktime.try(:type)
          doc.duration(d.duration.length) if d.duration.try(:length)
          doc.hours_per_week(d.worktime.hours_per_week) if d.worktime.try(:hours_per_week)

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
