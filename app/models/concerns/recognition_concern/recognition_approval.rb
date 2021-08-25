module RecognitionConcern
  module RecognitionApproval
    extend ActiveSupport::Concern

    included do
      has_many :approvals, -> {includes :giver }, class_name: "RecognitionApproval", dependent: :destroy
    end

    def approval_for(user)
      # self.approvals.where(giver_id: user.id).limit(1).first
      self.approvals.detect{|a| a.giver_id == user.id}
    end

    def approved_by?(user)
      self.approval_for(user).present?
    end

    def approvable_by?(user, company_id)
      if user.kind_of?(User)
        # must not be the sender or the recipient
        return !participants.include?(user) && participant_company_ids.include?(company_id)
      end

      return false
    end
    
    def has_approvals?
      return approvals.size > 0
    end

    def approvers
      approvals.collect{|a| a.giver}
    end

    def approve_by(user, additional_attrs = {})
      approval = build_approval(user, additional_attrs)
      approval.save
      return approval
    end

    def build_approval(user, additional_attrs = {})
      approval = self.approvals.build(giver: user)
      approval.assign_attributes(additional_attrs)
      approval
    end
  end
end