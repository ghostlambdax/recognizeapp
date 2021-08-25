class AddApprovalWorkflowAttributesToRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :resolver_id, :integer
    add_column :recognitions, :denial_message, :text,  limit: 4_294_967_295
    add_column :recognitions, :status_id, :integer, null: false

    return if Rails.env.test?
    # Since, approval workflow is new, make all past recognitions approved by the system user.
    reversible do |direction|
      direction.up do
        Recognition.reset_column_information
        Recognition.update_all(
          status_id: Recognition.status_id_by_name(:approved),
          resolver_id: User.system_user.id
        )
      end
    end
  end
end
