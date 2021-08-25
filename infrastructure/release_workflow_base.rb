require 'octokit'
require 'yaml'

# REQUIREMENTS: (aka TODO: build these checks into code)
#   1. No local git diff. Everything must be stashed or checkedout and ideally synced with remote.
#   2. Make sure you have a valid git connection (ssh-add if you need to) to pull and push
class ReleaseWorkflowBase
  attr_reader :client, :repo

  def initialize
    home_dir = `echo $HOME`.strip
    gh_hosts_config_path = File.join(home_dir,"/.config/gh/hosts.yml")
    gh_hosts_config = YAML.load(File.read(gh_hosts_config_path))
    token = gh_hosts_config["github.com"]["oauth_token"]
    @client = Octokit::Client.new(:access_token => token)
    @repo = 'recognize/recognize'
  end

  def project(name: "Main Release Schedule")
    @project ||= client.projects(repo, project_api_opts).detect{ |proj| proj[:name] == "Main Release Schedule" }
  end

  def project_api_opts
    preview_accept_header = 'application/vnd.github.inertia-preview+json'
    project_api_opts = {accept: preview_accept_header}
  end

  def project_columns
    @project_columns ||= client.project_columns(project[:id], project_api_opts)
  end

  def project_column(name)
    project_columns.detect{ |pc| pc[:name] == name }
  end

  def release_candidate_column
    @release_candidate_column ||= project_column("Release Candidate")
  end

  def merged_into_develop_column
    @merged_into_develop_column ||= project_column("Merged into Develop")
  end

  def in_production_column
    @in_production_column ||= project_column("In Production")
  end
  
end
