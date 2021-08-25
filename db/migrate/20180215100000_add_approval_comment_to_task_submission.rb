class AddApprovalCommentToTaskSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :task_submissions, :approval_comment, :text, limit: 4294967295
  end
end
