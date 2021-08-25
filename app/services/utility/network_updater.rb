module Utility
  class NetworkUpdater
    attr_reader :company, :new_network

    def initialize(company, new_network, opts = {})
      @company = company
      @new_network = new_network
    end

    def ok_to_update?
      existing_domains = CompanyDomain.where(domain: new_network)
      existing_domains.all?{|ed| ed.company_id == company.id }
    end

    def update!
      raise "Not ok to update network" unless ok_to_update?

      company.update_column(:domain, new_network)

      # if there is also a company domain for this network
      # skip changing company domain
      unless company.domains.any?{|cd| cd.domain == new_network }
        company.domains.where(domain: company.domain).first.update_column(:domain, new_network)
      end

      User.where(company_id: company.id).update_all(network: new_network)
      PointActivity.where(company_id: company.id).update_all(network: new_network)
      RecognitionRecipient.where(recipient_company_id: company.id).update_all(recipient_network: new_network)
      Team.where(company_id: company.id).update_all(network: new_network)
    end
  end
end