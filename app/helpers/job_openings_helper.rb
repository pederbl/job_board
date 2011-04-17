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

  def location(job = nil)
    job = @job unless job
    return nil unless job.location
    return nil unless job.location.country
    loc = job.location
    arr = []
    arr << t("iso_3166_1_alpha_2.#{loc.country}").titleize
    arr << loc.region if loc.region
    arr << loc.city if loc.city
    arr.reverse.join(", ")
  end

  def attrs_location(attrs)
    [attrs[:country], attrs[:region], attrs[:city]].reject { |s| s.blank? }.reverse.join(", ")
  end

  def isco_translation(job = nil)
    job = @job unless job
    isco = job.isco.to_s.split(".").first.gsub(/0+$/, "")
    translation = nil
    while translation.nil?
      translation = t("isco_code.#{isco}", default: "MISSING")
      translation = nil if translation == "MISSING"
      isco.gsub!(/.$/, "") if translation.nil?
    end
    translation
  end

  def worktime_string(job = nil)
    job = @job unless job 
    return nil if job.worktime.nil?
    arr = []
    arr << t("job_openings.job_information.worktime_type.#{job.worktime.type}") if job.worktime.type
    arr << "#{job.worktime.hours_per_week} #{t("job_openings.job_information.hours_per_week")}" if job.worktime.hours_per_week and job.worktime.hours_per_week > 0.0
    return nil if arr.blank?
    return arr.join(", ")
  end

  def info_string(job)
    worktime = worktime_string(job)
    duration = job.duration.try(:length) ? t("job_openings.job_information.length_type.#{job.duration.length}") : nil
    d = job.salary
    salary = if d and d.minimum and d.currency and d.period
      period = t("job_openings.job_information.salary_period.#{d.period}")
      "#{d.minimum} #{d.currency} / #{period}" 
    else
      nil 
    end
    [worktime, duration, salary].compact.join(", ")
  end

  def attrs_worktime_string(attrs)
    type = t("job_openings.job_information.worktime_type.#{attrs[:worktime]}") if attrs[:worktime].present?
    hours_per_week = "#{attrs[:hours_per_week]} #{t("job_openings.job_information.hours_per_week")}" if attrs[:hours_per_week] != 0.0
    arr = [type, hours_per_week].reject { |s| s.blank? }
    return arr.blank? ? nil : arr.join(", ")
  end

  def attrs_info_string(attrs)
    worktime = attrs_worktime_string(attrs)
    duration = nil
    salary = nil
    duration = t("job_openings.job_information.length_type.#{attrs[:duration]}") if attrs[:duration].present?
    salary = if attrs[:minimum_salary] != 0.0 and attrs[:salary_currency].present? and attrs[:salary_period].present?
      period = t("job_openings.job_information.salary_period.#{attrs[:salary_period]}")
      "#{attrs[:minimum_salary]} #{attrs[:salary_currency]} / #{period}" 
    else
      nil
    end
    arr = [worktime, duration, salary].compact
    return arr.blank? ? nil : arr.join(", ")
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
    return (
      d.present? and 
      (
        (d.minimum and d.minimum > 0.0) || 
        (d.maximum and d.maximum > 0.0) || 
        d.accommodation.present? || 
        d.meals.present? || 
        d.travel_expenses.present? || 
        d.relocation.present? || 
        d.text.present?
      )
    )
  end

  def show_requirements
    d = @job.requirements
    return (d.present? and (d.drivers_license.present? || d.education || d.experience || d.own_car || d.minimum_age || d.maximum_age || d.text || d.languages.present?).present?)
  end

end
