# config valid only for current version of Capistrano
lock '3.11.0'

set :application, "recognize"
set :repo_url,  "git@github.com:recognize/recognize.git"

set :rvm_ruby_string, :local
set :rails_env, "production" #added for delayed job, see https://github.com/collectiveidea/delayed_job/wiki/Rails-3-and-Capistrano
set :delayed_job_server_role, :delayed_job
set :delayed_job_default_hooks, false

set :ssh_options, {:forward_agent => true}
set :branch, "master"
set :deploy_via, :remote_cache
set :deploy_to, "/home/ec2-user/sites/recognizeapp.com"
set :backup_to, "/home/ec2-user/sites/recognizeapp.com/shared/backups"

set :user, "ec2-user"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
set :pty, true

# set :sshkit_backend, AutoAskNetSshBackend

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/local.yml', 'config/credentials.yml', 'config/newrelic.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

set(:config_files, %w(
  database.yml.sample
  local.yml.sample
  credentials.yml.sample
  newrelic.yml.sample
))

set :newrelic_env, fetch(:rails_env, 'production')


set :db_remote_clean, true
set :disallow_pushing, true
set :local_db_dir, "tmp"
set :dump_cmd_flags, '--default-character-set=utf8mb4'
set :prefix_db_with_stage, true

module Slackistrano
  class CustomMessaging < Messaging::Base
      def icon_url
        'https://recognizeapp.com/assets/chrome/logo_180x180.png'
      end

      def username
        'recognizebot'
      end

      # Override the deployer helper to pull the best name available (git, password file, env vars).
      # Copied from https://github.com/phallstrom/slackistrano
      def deployer
        name = `git config user.name`.strip
        name = nil if name.empty?
        name ||= Etc.getpwnam(ENV['USER']).gecos || ENV['USER'] || ENV['USERNAME']
        name
      end
  end
end

set :slackistrano, {
  klass: Slackistrano::CustomMessaging,
  channel: '#engineering', 
  webhook: 'https://hooks.slack.com/services/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',
}
# set :slack_webhook, "https://hooks.slack.com/services/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"
# set :slack_icon_url, "https://recognizeapp.com/assets/chrome/logo_180x180.png"
# set :slack_username, "recognizebot"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  # before :deploy, "deploy:check_revision"
  # after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after 'deploy:publishing', 'deploy:restart'  

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end  

  desc 'manually kill delayed jobs'
  task :kill_the_dj do 
    on roles(:delayed_job) do 
      execute "cat #{release_path.join("tmp/pids/*.pid")} |xargs -I {} kill -INT {}"
    end
  end

end

# before 'deploy:finished', 'newrelic:notice_deployment'
after 'deploy:started', 'stop_delayed_job' do
  invoke 'delayed_job:stop'
  invoke 'deploy:kill_the_dj' rescue nil
end

# after "deploy:assets:precompile", "deploy:assets:compile_themes"
after "deploy:assets:precompile", "deploy:assets:non_digested"
after "deploy:assets:precompile", "deploy:assets:copy_extension_htaccess"

before "deploy:finished", "delayed_job:start"
after "deploy:finished", "utils:say_deploy_complete"

