set :stage, 'https://whitney.recognizeapp.com'
# set :branch, (ENV['DEPLOY_BRANCH'] || 'master')
set :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :host, "whitney.recognizeapp.com"
set :deploy_to, "/home/web/sites/whitney.recognizeapp.com"
set :backup_to, "/home/web/sites/whitney.recognizeapp.com/shared/backups"

set :delayed_job_workers, 1
set :delayed_job_queues, ['*']
set :delayed_job_pools, {
  '*' => 1
}
set :delayed_job_roles, [:app, :background, :delayed_job]
set :rvm_roles, [:web, :app, :db, :background, :delayed_job]
set :keep_releases, 1

server '54.244.90.62', 
  user: 'web', 
  port: 22, 
  roles: %w{web app db delayed_job}

namespace :deploy do
  task :clean_disk do
    on roles(:app) do    
      execute "echo -n "" > ./sites/whitney.recognizeapp.com/current/log/production.log" 
      execute "echo -n "" > ./sites/whitney.recognizeapp.com/current/log/delayed_job.log" 
      execute "rm -fr ./sites/whitney.recognizeapp.com/current/tmp/cache/*" 
    end
  end
end

before 'deploy:started', 'deploy:clean_disk'

