module CloseioClient

  def self.init(api_key)
    (api_key.present? && !Rails.env.test?) ? Closeio::Client.new(api_key) :  MockClient.new
  end

  def self.client_for_sequence_subscriptions
    # If we have a specialized sequence api key
    # use that client
    # otherwise, fallback to the standard client
    sequence_api_key = InternalSetting.close_sequence_api_key
    sequence_api_key.present? ? init(sequence_api_key) : Recognize::Application.closeio
  end

  def self.included(base)
    base.class_eval do

      def closeio
        @closeio_client ||= ::CloseioClient.init(closeio_api_key)
      end

      def closeio_api_key
        return nil unless Credentials.credentials_present?("closeio", ["api_key"])

        Recognize::Application.config.rCreds["closeio"]["api_key"]
      end

    end
    Closeio::Client.send(:include, Extensions)
    MockClient.send(:include, Extensions)
  end

  class MockClient
    def delayable
      self
    end

    def live?
      false
    end

    def list_custom_fields
      return {
        data: [{
          label: "cool",
          id: "1234",
          name: "Name of field"
        }]
      }
    end

    def list_lead_statuses
      return {
        data: [
          {
            label: "Label",
            id: 1234
          }
        ]
      }
    end

    def list_leads(*args)
      return {}
    end

    def upsert_contact(*args)
      find_lead_and_contact_for(*args)
    end

    def find_lead_and_contact_for(*args)
      [Hashie::Mash.new(id: "", status_label: ""), Hashie::Mash.new(id: "", status_label: "")]
    end

    def create_lead(*args)
      return Hashie::Mash.new()
    end

    def update_lead(*args)
      return Hashie::Mash.new()
    end

    def email_template_by_name(name)
      Hashie::Mash.new({"body"=>
      "{{contact.first_name}},<br><br>We received your inquiry in regards to our Recognition platform and our team is excited to demonstrate how we can help {{lead.name}} unlock your employees potential. I've included some best practices below for review. Please answer the following questions so we can better prepare for a demonstration.<br><br><ol><li>How many total employees are there in your organization?</li><li>Do you use an internal platform such as Yammer, Slack, Sharepoint, Jira, etc?</li><li>Are you interested in our native mobile application for outside employees?&nbsp;</li><li>When are you and your team available for a demo?&nbsp;</li></ol><br>Engagement strategy overview:<br><ul><li>Stream the recognitions on a TV in the lobby for top-of-mind.    </li><li>Create three rewards that are easy to administer, create experiences for staff, and are close to free (parking spot, pizza party for team at end of day, half day off).    </li><li>Nominate staff through a nomination custom badge. Acknowledge these employees each month in a company email.&nbsp;</li></ul><br>You can review our Best Practices Handbook here:&nbsp;<a href=\"https://recognizeapp.com/best-practices-handbook.pdf\" target=\"_blank\">https://recognizeapp.com/best-practices-handbook.pdf</a><br><br>Read our strategy here:&nbsp;<a href=\"https://recognizeapp.com/company-engagement-strategy.pdf\" target=\"_blank\">https://recognizeapp.com/company-engagement-strategy.pdf</a><br><br>Go to&nbsp;<a href=\"http://support.recognizeapp.com/\" target=\"_blank\">http://support.recognizeapp.com</a>&nbsp;for our knowledge base.<br><br>Email&nbsp;<strong><a href=\"mailto:support@recognizeapp.com\" target=\"_blank\">support@recognizeapp.com</a></strong>&nbsp;if you need anything.<br><br>We look forward to the working with you.<br><br>Cheers,<br><br>",
       "attachments"=>[],
       "name"=>"Initial email response",
       "date_updated"=>"2016-01-15T16:22:21.974000+00:00",
       "created_by"=>"user_285b6Uo64w1sDxsaSMQzh58GXy1uiFsoVpmfwAvqsXR",
       "body_preview"=>
        "{{contact.first_name}},  We received your inquiry in regards to our Recognition platform and our team is excited to demonstrate how we can help {{lead.name}} unlock your employees potential. I've incl",
       "organization_id"=>"orga_BkzrERY8EYZr365BodfUCExnpP1tkydIwxFwxg6u5Qo",
       "updated_by"=>"user_285b6Uo64w1sDxsaSMQzh58GXy1uiFsoVpmfwAvqsXR",
       "date_created"=>"2016-01-11T22:16:07.902000+00:00",
       "subject"=>"Recognize",
       "id"=>"tmpl_mpsXddywjdkka8TCHKgTZUn2cTDRSSeAHV9GzuktiTa",
       "is_shared"=>true})
    end

    def render_email_templates(*args)
      Hashie::Mash.new(subject: "This is the subject", body: "This is the body")
    end

    def method_missing(m, *args, &block)
      log "#{m} - #{args}"
      return Hashie::Mash.new(id: "")
    end

    def log(msg)
      Rails.logger.debug "[CloseioClient::MockClient] #{msg}"
    end
  end

  module Extensions

    MultipleLeadsForCompanyException = Class.new(StandardError)

    def live?
      true
    end

    def find_lead_for_company(company)
      subdomains = ["", "www."]
      protocols = ["http", "https"]

      query = protocols.map{|pr| subdomains.map{|sub| "lead_url:'#{pr}://#{sub}#{company.domain}'"}}.join(" OR ")
      response = Hashie::Mash.new list_leads(query)

      return nil if response.total_results.zero?
      return response.data[0] if response.total_results == 1

      filtered_results = response.data.select{|d| d["status_label"] == "Contract signed"}
      return filtered_results[0] if filtered_results == 1

      raise ::CloseioClient::Extensions::MultipleLeadsForCompanyException

    rescue ::CloseioClient::Extensions::MultipleLeadsForCompanyException => e
      ExceptionNotifier.notify_exception(e, data: { company: company.domain})
      return response.data[0]
    end

    def find_lead_and_contact_for(user)
      lead = find_lead_for_company(safe_company(user))
      contact = contact_from_lead(lead, user)
      return [lead, contact]
    end

    def get_lead_status_id_by_name(lead_name)
      id = nil

      Recognize::Application.closeio.list_lead_statuses['data'].each do |status|
        if status["label"] == lead_name
          id = status["id"]
          break
        end
      end

      return id
    end

    def custom_fields
      @custom_fields ||= Recognize::Application.closeio.list_custom_fields['data']
    end

    # This returns a fresh client object instance without any instance variables
    # so it will be safe to stash into database for delayed jobs
    def delayable
      CloseioClient.init(self.api_key)
    end

    def get_custom_field_id_by_name(name)

      field = self.custom_fields.detect do |field|
        field['name'] == name
      end

      if field
        return "custom.#{field['id']}"
      else
        return nil
      end
    end

    def upsert_contact(user_or_id, opts = {})
      user = user_or_id.kind_of?(User) ? user_or_id : User.find(user_or_id)
      company = safe_company(user)
      lead, contact = find_lead_and_contact_for(user)

      if lead.present?
        Rails.logger.info "Upserting contact to Close(existing lead): #{user.email}"
        response = update_lead(lead['id'], lead_payload(user, lead, contact, opts))
      else
        Rails.logger.info "Upserting contact to Close(creating lead): #{user.email}"
        response = create_lead(lead_payload(user, nil, nil, opts))
      end

      lead = response
      contact = contact_from_lead(lead, user)
      return [lead, contact]
    end

    def lead_payload(user, existing_lead=nil, existing_contact=nil, opts = {})
      params = opts
      company = safe_company(user)

      params[:name] = company.try(:name) || company.domain unless existing_lead.present?
      params[:url] = company.domain
      params[:contacts] = [contact_payload(user, existing_contact)]

      params[:requested_user_count] = company.requested_user_count if company.requested_user_count.present?
      params[get_custom_field_id_by_name("auth - yammer")] = true if user.authentications.yammer.present?
      params[get_custom_field_id_by_name("auth - office365")] = true if user.authentications.microsoft_graph.present?
      params[get_custom_field_id_by_name("auth - google")] = true if user.authentications.google.present?
      params[get_custom_field_id_by_name("tld")] = company.tld

      return params
    end

    # method for specifically only updating custom fields to a lead
    # opts should be {field_id => value}
    def update_lead_custom_fields(company, opts = {})
      lead = find_lead_for_company(company)

      if lead.present?
        Recognize::Application.closeio.delayable.delay(queue: "sales").update_lead(lead.id, opts)
      end
    end

    def safe_company(user)
      user.try(:company) || Company.from_email(user['email'])
    end

    NAME_PLACEHOLDER = ""
    COMPANY_ADMIN_PLACEHOLDER = "https://companyadmin.example.com"
    def contact_payload(user, existing_contact=nil)

      data = {
        emails: [{type: "office", email: user['email']}]
      }

      data[:title] = user['job_title'] if user['job_title'].present?

      # Name
      if existing_contact.present? && existing_contact['name'].present?
        data[:name] = existing_contact['name']
      else

        if user['first_name'].present? && user['last_name'].present?
          data[:name] = "#{user['first_name']} #{user['last_name']}"
        elsif user['first_name'].present?
          data[:name] = user['first_name']
        end
      end

      data['id'] = existing_contact.id if existing_contact

      if user.phone
        existing_phone_numbers = existing_contact && existing_contact['phones'] || []
        if !existing_phone_numbers.map(&:phone).include?(user['phone'])
          data['phones'] = existing_phone_numbers + [{type: "office", phone: user['phone']}]
        end
      end

      if user.company_admin?
        data['urls'] = [{url: COMPANY_ADMIN_PLACEHOLDER, type: "url"}]
      end

      return data
    end

    def email_template_by_name(name)
      set = list_email_templates
      return nil if set['total_results'] == 0
      return set['data'].detect{|template| template['name'] == name}
    end

    def contact_from_lead(lead, user)
      return nil unless lead.present? && lead['contacts'].present?
      lead['contacts'].detect{|c| c['emails'].detect{|e| e['email'].downcase == user['email'].downcase}}
    end
  end
end
