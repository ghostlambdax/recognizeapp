# NOTE: this uses gh to setup the OAuth application token
#       https://cli.github.com/manual/
#       MAC: brew install gh
#            gh auth login # then follow the prompts to go through browser authentication
#
# USAGE: (in irb)
#         require './infrastructure/create_release_workflow'
#         CreateReleaseWorkflow.run!
#         CreateReleaseWorkflow.run!(branch_suffix: "b") # for when there is a 2nd deployment on the same day, and so on.
#
# TODO: 
#   * there isn't an existing release, or if so, increment to "b", "c" release versions, etc.
require_relative './release_workflow_base'
class CreateReleaseWorkflow < ReleaseWorkflowBase
  MAIN_BRANCH = "main" 

  attr_reader :branch_name, :release_pr

  def self.run!(opts = {})
    workflow = self.new(opts)
    workflow.create_release_branch
    workflow.create_release_pr
    workflow.move_merged_prs_to_rc_column
    workflow.add_pr_to_project
  end

  def initialize(opts = {})
    super()
    @branch_name = "releases/#{Time.now.strftime("%Y%m%d")}#{opts[:branch_suffix]}"
  end

  def create_release_branch
    puts "Creating release branch: #{branch_name}"
    `git checkout develop`
    `git pull origin develop`
    `git checkout -b #{branch_name}`
    `git push origin HEAD`
  end

  def create_release_pr
    @release_pr = client.create_pull_request(repo, MAIN_BRANCH, branch_name, branch_name)
  end

  def add_pr_to_project
    client.create_project_card(release_candidate_column[:id], content_id: release_pr[:id], content_type: "PullRequest")
  end

  def move_merged_prs_to_rc_column

    issue_cards = client.column_cards(merged_into_develop_column[:id], project_api_opts)
    issue_cards.each {|card| client.move_project_card(card[:id], 'top', project_api_opts.merge( {column_id: release_candidate_column[:id] } )) }

  end

  def release_pr
    @release_pr || client.pull_requests(repo, base: 'main').first
  end

end
