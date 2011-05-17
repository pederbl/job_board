set :output, "/home/ec2-user/log/whenever.log"
job_type :thor, "cd :path && RAILS_ENV=:environment thor :task :output"

every 1.day, at: "4am" do 
#  rake "sitemap:refresh"
#  thor "sphinx:index_job_openings_main"
end

every 1.day, at: "4pm" do 
  runner "ECB::Client.sync_currency_rates"
end

every 1.day, at: "4:30 pm" do 
  runner "SalaryNormalizer.normalize_salaries"
end

every 10.minutes do 
  runner "SalaryNormalizer.update_highest_paid_jobs"
  runner "Addthis::Client.sync_most_shared_jobs" 
end


# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end
