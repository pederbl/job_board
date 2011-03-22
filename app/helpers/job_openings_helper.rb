module JobOpeningsHelper

  def title
    if params[:action] == 'show'
      "Jobb: #{@job_opening.t(:title)}"
    else
      "Lediga jobb"
    end
  end

end
