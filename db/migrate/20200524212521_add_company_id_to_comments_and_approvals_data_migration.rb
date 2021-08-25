class AddCompanyIdToCommentsAndApprovalsDataMigration < ActiveRecord::Migration[5.0]
  def up
    # Migrate data for dev environments only
    # Since these are long running updates, I want the deployment to proceed
    # and then will issue these updates manually on the servers
    # No code depends on this until this is deployed and the data is updated
    if Rails.env.development?
      puts " ------------------- "
      puts "Hi there. We need to update your data to add company id to Comments and RecognitionApprovals"
      puts "Depending on the size of your database this might take a few minutes."
      puts "Please standby... :) "
      Comment.joins(:commenter).update_all("comments.company_id = users.company_id")
      RecognitionApproval.joins(:giver).update_all("recognition_approvals.company_id = users.company_id")
      puts "Ok, we're all set. Have fun!"
      puts " ------------------- "
    end
  end
end
