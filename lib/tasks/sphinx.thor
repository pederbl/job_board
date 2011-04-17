class Sphinx < Thor

  require File.expand_path('config/environment.rb') 
  require "builder"

  desc "job_openings", "output xmlpipe for job openings"
  def job_openings
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

      ids = JobOpening.where(deleted_at: nil).desc(:publish_at).map(&:id)
      ids.each_with_index { |id, idx|
        d = JobOpening.find(id)
        next if d.deleted_at
        docset.send("sphinx:document", id: idx + 1) do |doc|
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

end
