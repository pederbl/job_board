module JobOpeningsHelper

  def title
    if params[:action] == 'show'
      arr = []
      arr << @job_opening.t(:title) if @job_opening.title
      at = []
      at << @job_opening.employer.name if @job_opening.employer.name
      at << @job_opening.location.region if @job_opening.location.try(:region)
      at << @job_opening.location.country if @job_opening.location.try(:country)
      arr << at.join(", ") if at.present?
      "Jobb: #{arr.join(" @ ")}"
    else
      "Lediga jobb"
    end
  end

  def description
    str = "Ledigt jobb: #{@job_opening.t(:body)}"
    str = str[0..250] + "..." if str.length > 250
    str
  end

  def keywords
    arr = ["lediga jobb", "jobb"]
    arr += title.gsub(/(jobb:|[@,])/i, "").split(" ")
    arr.join(", ")
  end

end
