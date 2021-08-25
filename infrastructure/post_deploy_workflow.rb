require 'octokit'
require 'yaml'

# NOTE: this uses gh to setup the OAuth application token
#       https://cli.github.com/manual/
#       MAC: brew install gh
#            gh auth login # then follow the prompts to go through browser authentication
#
# USAGE: (in irb)
#         require './infrastructure/post_deploy_workflow'
#         PostDeployWorkflow.run!
require_relative './release_workflow_base'
class PostDeployWorkflow < ReleaseWorkflowBase

  def self.run!
    workflow = self.new
    workflow.merge_release_pr_into_main
    workflow.merge_main_back_to_develop
    workflow.manage_project_cards
  end

  def merge_release_pr_into_main
    release_prs = client.pull_requests(repo, base: 'main')
    raise "There is more than one release PR, so this needs to be handled manually" if release_prs.length > 1
    release_pr = release_prs[0]

    response = client.merge_pull_request(repo, release_pr[:number], '', merge_method: "merge")
    raise "Merge of release PR to main was not successful" unless response[:merged]
  end

  def merge_main_back_to_develop
    `git checkout main`
    `git pull origin main`
    `git checkout develop`
    `git pull origin develop`
    `git merge main`
    `git push origin develop`
  end

  def manage_project_cards
    issue_cards = client.column_cards(release_candidate_column[:id], project_api_opts)
    issue_cards.each {|card| client.move_project_card(card[:id], 'top', project_api_opts.merge( {column_id: in_production_column[:id] } )) }

    # get cards in develop column, and filter just on releases/* as there could be other cards already merged into develop by now
    release_cards = client.column_cards(merged_into_develop_column[:id], project_api_opts).select do |card| 
      card_content_url = card[:content_url]
      card_content = client.get(card_content_url)
      if card_content.key?(:pull_request)
        pr_url = card_content[:pull_request][:url]
        pr = client.get(pr_url)
        pr[:title].match(/^releases.*/) 
      else
        false
      end
    end
    release_cards.each {|card| client.move_project_card(card[:id], 'top', project_api_opts.merge( {column_id: in_production_column[:id] })) }
  end
end


