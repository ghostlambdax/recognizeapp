class RenameCategoryToTag < ActiveRecord::Migration[5.0]
  def change
    rename_table :categories, :tags

    add_column :tags, :is_recognition_tag, :boolean, default: false
    add_column :tags, :is_task_tag, :boolean, default: false

    rename_column :tasks, :category_id, :tag_id
    rename_column :completed_tasks, :category_id, :tag_id

    # As the existing rows are all categories tied to tasks, set `is_task_tag` to `true`.
    Tag.update_all(is_task_tag: true)
  end
end
