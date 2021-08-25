class Tag < ActiveRecord::Base
  belongs_to :company, inverse_of: :tags

  has_many :tasks, inverse_of: :tag, class_name: "Tskz::Task"
  has_many :completed_tasks, inverse_of: :tag, class_name: 'Tskz::CompletedTask'

  has_many :recognition_tags, inverse_of: :tag, dependent: :destroy
  has_many :recognitions, through: :recognition_tags

  validates :company, presence: true
  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }

  after_update :update_tag_names_in_recognition_tags, if: :name_changed?

  scope :recognition_taggable, -> { where(is_recognition_tag: true) }
  scope :task_taggable, -> { where(is_task_tag: true) }


  private

  def update_tag_names_in_recognition_tags
    RecognitionTag.where(tag_id: self.id).update_all(tag_name: self.name)
  end

  # def self.clean_up
  #   tag_ids_without_tasks_or_completed_tasks = self
  #                                                .includes(:tasks, :completed_tasks)
  #                                                .where(tasks: {id: nil}).where(completed_tasks: {id: nil})
  #                                                .pluck(:id)
  #
  #   where(id: tag_ids_without_tasks_or_completed_tasks).delete_all
  # end
end
