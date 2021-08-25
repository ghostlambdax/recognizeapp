# http://blog.sosedoff.com/2011/08/10/capistrano-mysql-backups-for-rails/
def remote_file_exists?(full_path)
  # 'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  test("[ -f #{full_path}]")
end

namespace :utils do
  # NOTE: this has been replaced with:
  #       bin/sync_db <environment>

  # desc 'Backup database before deploy'
  # task :backup do
  #   invoke 'utils:db:sync'
  # end

  # namespace :db do
  #   desc 'Sync db'
  #   task :sync do
  #     invoke 'db:pull'
  #     on roles(:db) do
  #       run_locally do
  #         with rails_env: :development do
  #           %x( rake 'recognize:sanitize_db' )
  #           %x( rake 'db:migrate')
  #         end # with rails_env
  #       end # run locally
  #     end # on roles(:db)
  #   end # sync task
  # end # db namespace

  desc "ssh bash shell"
  task :bash do

    on roles(:app) do
      user = fetch(:user)
      port = fetch(:port) || 22
      cmd = "ssh -l #{user} #{host} -p #{port} -t "
      system cmd
    end

  end

  desc "get users emails who have not unsubscribed"
  task :user_list do
    filename = "user_list.csv"
    local_filepath = "tmp/#{filename}"
    run("cd #{deploy_to}/current && /usr/bin/env bundle exec rake recognize:user_list filename=#{local_filepath} RAILS_ENV=production")
    download("#{deploy_to}/current/#{local_filepath}", local_filepath)
  end

  desc 'Show deployed revision'
  task :revision do
    on roles(:app) do
      execute "cat #{current_path}/REVISION"
    end
  end

  desc 'Say deploy has finished'
  task :say_deploy_complete do
    on roles(:app) do
      run_locally do
        host = fetch(:host).gsub('.recognizeapp.com', '')
        execute "say \"Yoyo $USER, the deploy of `git rev-parse --abbrev-ref HEAD` to #{host} has finished. Dont forget to compile themes if necessary.\"",
                raise_on_non_zero_exit: false # not available in linux
      end
    end
  end

end

