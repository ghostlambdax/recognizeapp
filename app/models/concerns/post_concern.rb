# methods relating to both Recognition or Nomination
module PostConcern
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def find_recipient_from_signature(sig, company = nil)
      klass, id = sig.split(":")
      model = klass.constantize
      recipient_scope = company.present? ? model.where(company_id: company.id) : model
      recipient_scope.find(id) rescue nil
    end
  end
end
