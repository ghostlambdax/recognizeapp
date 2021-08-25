class CopyDataFromApproversToApproverInBadges < ActiveRecord::Migration[5.0]

  class Badge < ApplicationRecord
    serialize :approvers, Array
  end

  def up
    Badge.where.not(approvers: nil).each do |badge|
      begin
        # Note: Although `approvers` is a serialized array, the code base only allowed 1 element inside the array. So
        # copy the only element over.
        badge.update_column(:approver, badge.approvers.first)
      rescue => e
        Rails.logger.warn "Data migration `CopyDataFromApproversToApproverInBadges` failed for badge(id: #{badge.id})! #{e}"
      end
    end
  end

  def down
    Badge.where.not(approver: nil).update_all(approver: nil)
  end
end
