class CreateActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :categories do |t|
      t.integer :company_id, null: false
      t.string :name, null: false
      t.index :company_id
    end

    create_table :tasks do |t|
      t.integer :company_id, null: false
      t.string :name, null: false
      t.integer :category_id
      t.integer :interval_id
      t.integer :frequency
      t.float :value      
      t.datetime :disabled_at
      t.index :company_id
    end

    create_table :activities do |t|
      t.integer :company_id, null: false
      t.text :description
      t.integer :submitter_id, null: false
      t.integer :status_id, null: false
      t.integer :approver_id
      t.datetime :resolved_at
      t.index :company_id
      t.index :submitter_id
      t.index [:company_id, :submitter_id]
    end

    create_table :completed_tasks do |t|
      t.integer :company_id, null: false
      t.integer :activity_id, null: false
      t.integer :task_id, null: false
      t.integer :status_id, null: false
      t.integer :category_id
      t.float :value
      t.integer :quantity
      t.text :comment
      t.index :company_id
      t.index :category_id
    end

  end
end
