require JobOpeningModels::JobOpeningModelsEngine.root.join("app", "models", "job_opening")
class JobOpening
  #BASE_URL = "http://ec2-46-137-5-1.eu-west-1.compute.amazonaws.com"
  include Mongoid::Document
  include Mongoid::TranslatedStrings

  index :slug, unique: true
  index :deleted_at
  index "salary.normalized_salary"
  index :publish_at


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

  private

  def self.wrap_wildcards(s)
    s.split(" ").map { |word| "*#{word}*" }.join(" ")
  end

end
