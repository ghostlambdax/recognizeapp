set :output, "#{path}/log/cron_log.log"

# every 1.hour do
#   command "#{path}/script/delayed_job_monitor"
# end
#

# every 1.day, at: "7:00 AM", roles: [:cron] do
#   script "delayed_job restart"
# end

# every :saturday, at: "2:00 AM", roles: [:cron] do
#   rake "recognize:backup_and_upload"
# end
# every 1.minutes do
#   runner "Time; puts User.find(6159).full_name;puts Time.now.to_f.to_s"
# end

every 1.day, at: "9:00 AM" do
  runner "Company.analytics_data.refresh!;puts Company.analytics_data"
end

every 1.day, at: "10:00AM" do
  runner "ExternalActivities::SyncService.sync_all_yammer_activities"
end

every 1.day, at: "11:00 AM" do
  runner "UserSyncService.sync"
end

every 1.day, at: "05:00 PM" do
  runner "Rewards::RewardService.sync_provider_rewards"
end

every 1.hour do
  runner "Points::Resetter.run_scheduler"
  runner "DailyEmailService.run"
  runner "EngagementReports.run"
  runner "Anniversary::ManagerNotifier.notify_all_anniversaries"
  runner "Anniversary::Recognizer.send_recognitions!"
  runner "DailyCompanyStatRunner.run!"
end

every 30.minutes do
  runner "Report::CacheManager::Company.bust_and_reprime_all_report_caches_if_necessary!"
end

every 30.minutes do
  runner "IpChecker::FbCrawler.cache_ips"
  runner "Report::Companies.expire_caches!"
  runner "Report::Companies.all.companies"
end


every 1.day, at: "4:00PM" do
  runner "NewCompanyAdminDigest.send!"
  runner "IpChecker::GhostInspector.cache_ips"
end



every 1.day, at: "1:00PM" do
  # rake 'recognize:generate_daily_sample_data'
end
