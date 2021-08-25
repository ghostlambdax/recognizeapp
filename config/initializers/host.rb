class Rails::Application::Configuration
  def web_protocol
    local_config["using_ssl"] ? "https://" : "http://"
  end

  def web_host
    web_protocol+host
  end

  def current_release
    info = local_config["current_release_info"]
    git_branch = -> { `git rev-parse --abbrev-ref HEAD`.chomp }
    if Rails.env.production?
      if info.present? && info.include?(",")
        branch, commit_str, pr_url = info.split(",")
        release_type, commit, build_number = commit_str.split("_")
      else
        branch = git_branch.()
        commit_str, commit, pr_url, build_number = ['N/A'] * 4
      end
    else
      branch = git_branch.()
      commit_str, commit, pr_url, build_number = ['DEV'] * 4
    end
    Hashie::Mash.new({
      branch: branch,
      commit_str: commit_str,
      commit: commit,
      pr_url: pr_url,
      build_number: build_number
    })
  end
end
