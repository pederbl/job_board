module JobOpeningsHelper

  def title
    if params[:action] == 'show'
      arr = []
      arr << @job.t(:title) if @job.title
      at = []
      at << @job.employer.name if @job.employer.try(:name)
      at << @job.location.region if @job.location.try(:region)
      at << @job.location.country if @job.location.try(:country)
      arr << at.join(", ") if at.present?
      "Jobb: #{arr.join(" @ ")}"
    else
      "Lediga jobb"
    end
  end

  def description
    str = "Ledigt jobb: #{@job.t(:body)}"
    str = str[0..250] + "..." if str.length > 250
    str
  end

  def keywords
    arr = ["lediga jobb", "jobb"]
    arr += title.gsub(/(jobb:|[@,])/i, "").split(" ")
    arr.join(", ")
  end

  def location
    return nil unless @job.location
    return nil unless @job.location.country
    loc = @job.location
    arr = []
    arr << t("iso_3166_1_alpha_2.#{loc.country}").capitalize
    arr << loc.region if loc.region
    arr << loc.city if loc.city
    arr.reverse.join(", ")
  end

  def worktime_string
    arr = []
    arr << t(".worktime_type.#{@job.worktime.type}") if @job.worktime.type
    arr << "#{@job.worktime.hours_per_week} #{t(".hours_per_week")}" if @job.worktime.hours_per_week
    return nil if arr.blank?
    return arr.join(", ")
  end

  def show_duration
    d = @job.duration
    return (d.present? and (d.length || d.starts_on || d.ends_on || d.sub || d.text).present?)
  end

  def show_worktime
    d = @job.worktime
    return (d.present? and (d.type || d.hours_per_week || d.text).present?)
  end

  def show_salary
    d = @job.salary
    return (d.present? and (d.minimum || d.maximum || d.accommodation || d.meals || d.travel_expenses || d.relocation || d.text).present?)
  end

  def show_requirements
    d = @job.requirements
    return (d.present? and (d.drivers_license.present? || d.education || d.experience || d.own_car || d.minimum_age || d.maximum_age || d.text || d.languages.present?).present?)
  end

end
