module Tskz
  class Task < ActiveRecord::Base
    include Authz::PermissionsHelper

    belongs_to :company, inverse_of: :tasks
    belongs_to :tag, inverse_of: :tasks, optional: true
    has_many :completed_tasks, inverse_of: :task
    attr_accessor :company_roles, :tag_name

    validates :company_id, :name, presence: true
    validates :points, numericality: { greater_than: 0 }, allow_blank: true

    def has_completed_tasks?
      self.completed_tasks.present?
    end

    def company_roles
      @company_roles ||= roles_with_permission(:send).map(&:id)
    end
    def tag_name
      @tag_name ||= tag.try(:name)
    end

    def toggle_status
      disabled_time = disabled_at? ? nil : Time.now
      update_column(:disabled_at, disabled_time)
    end

    def enabled?
      !disabled_at?
    end

    def disabled?
      !enabled?
    end

    def save_with_options
      begin
        transaction do
          assign_tag
          save!
          assign_roles if (company_roles.present?)
        end
        # Tag.delay(queue: 'caching').clean_up
        self
      rescue
        # noop
      end
    end

    def assign_tag
      if (tag_name)
        tag = Tag.find_or_create_by(name: tag_name.strip, company_id: self.company_id)
      end
      self.tag_id = tag.id if tag
    end

    def assign_roles
      new_roles = self.company.company_roles.where(id: company_roles).to_a
      grant_permission_to_roles(:send, new_roles)
    end
  end
end
