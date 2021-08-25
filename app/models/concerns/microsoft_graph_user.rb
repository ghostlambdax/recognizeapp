module MicrosoftGraphUser
  extend ActiveSupport::Concern

  included do    
  end

  module ClassMethods

    # meant to be run in background
    def sync_microsoft_graph_avatar(user_id)
      user = User.with_deleted.find(user_id)
      return if user.disabled?
      
      sync_user = user.microsoft_graph_sync_user
      return if sync_user.blank?

      photo = sync_user == user ? 
        sync_user.microsoft_graph_client.photo : 
        sync_user.microsoft_graph_client.users_photo(user)

        # FIXME: Grab user avatar, follow YammerUser#sync_yammer_avatar for example
        # http://www.davehulihan.com/uploading-data-uris-in-carrierwave/
        #   
        attachment = user.build_attachment_from(photo)
        if photo.present? && attachment.present?
          uploaded_file = ActionDispatch::Http::UploadedFile.new(attachment)
          user.update_avatar(file: uploaded_file)
        end
    rescue => e
      Rails.logger.debug "Error syncing avatar for #{user_id} - #{e.message}"
    end

    # meant to be run in background
    def sync_microsoft_graph_manager(user_id)
      user = User.find(user_id)
      sync_user = user.microsoft_graph_sync_user(admin_required: true)
      return if sync_user.blank?

      provider_manager = sync_user.microsoft_graph_client.manager(user)
      if provider_manager.present?
        recognize_manager_id = User.find_by(microsoft_graph_id: provider_manager.id).try(:id)
        user.update_column(:manager_id, recognize_manager_id) if recognize_manager_id.present?
      else
        user.update_column(:manager_id, nil) if user.manager_id.present?
      end

    rescue => e
      Rails.logger.debug "Error syncing manager for #{user_id} - #{e.message}"
    end

    def sync_metadata(user_id)
      user = User.find(user_id)
      return unless user.microsoft_graph_id.present?

      sync_user = user.microsoft_graph_sync_user(admin_required: true)
      company = user.company
      return if sync_user.blank?

      cf_mappings = company.custom_field_mappings
      ms_user = sync_user.microsoft_graph_client.user(user.microsoft_graph_id,
                                                      cf_mappings.microsoft_graph_query_attributes)
      attrs = {}

      if company.settings.sync_service_anniversary_data?      
        attrs[:birthday] = User.new(birthday: ms_user.birthday).send(:massage_birthyear)
        attrs[:start_date] = ms_user.start_date
      end

      if cf_mappings.present? && company.settings.sync_custom_fields?
        cf_mappings.each do |mapping|
          attrs[mapping.key.to_sym] = ms_user.value_for_custom_field_mapping(mapping)
        end
      end

      if company.allow_syncing_of_user_attributes_mapped_to_custom_field_mapping?
        attributes_mapped_to_cfms = user.attributes_mapped_to_custom_field_mappings(ms_user)
        attrs.merge!(attributes_mapped_to_cfms)
      end

      user.update_columns(attrs) if attrs.present?
    rescue RestClient::ResourceNotFound => e
      Rails.logger.debug "MGC#sync_service_metadata - Could not find user: #{user_id}"
    end
  end

  def attributes_mapped_to_custom_field_mappings(ms_user)
    attrs = {}
    return attrs unless self.company.allow_syncing_of_user_attributes_mapped_to_custom_field_mapping?

    custom_field_mappings = self.company.custom_field_mappings.custom_field_mapping
    custom_field_mappings_mapped_to_user_attributes = custom_field_mappings.select { |cfm| cfm.mapped_to.present? }

    custom_field_mappings_mapped_to_user_attributes.each  do |cfm|
      attribute_name = cfm.mapped_to.to_sym
      attrs[attribute_name] = ms_user.value_for_custom_field_mapping(cfm)
    end

    # Although CustomFieldMapping::MAPPABLE_USER_ATTRIBUTES might not have all the attributes below, be defensive by
    # doing an exhaustive check.
    attrs.delete(:birthday) unless self.sync_service_anniversary_data?
    attrs.delete(:start_date) unless self.sync_service_anniversary_data?
    attrs.delete(:phone) unless self.sync_phone_enabled?
    attrs.delete(:job_title) unless self.sync_job_title?
    attrs.delete(:display_name) unless self.sync_display_name?
    attrs.delete(:department) unless self.sync_department?
    attrs.delete(:country) unless self.sync_country?

    # Sanitize anniversary dates.
    ms_graph_default_time = MicrosoftGraphClient::MicrosoftUser::MS_DEFAULT_TIME
    attrs[:birthday] = MicrosoftGraphClient::MicrosoftUser.parse_ms_graph_birthday(attrs[:birthday])
    attrs[:start_date] = Time.parse(attrs[:start_date]) if attrs[:start_date].present? && attrs[:start_date] != ms_graph_default_time

    # Manually run logics that would have been otherwise triggered in before_validations.
    attrs[:birthday] = if attrs.has_key?(:birthday)
      u = User.new(birthday: attrs[:birthday]); u.send(:massage_birthyear); u.birthday
    end
    attrs[:locale] = if attrs.has_key?(:locale)
      u = User.new(locale: attrs[:locale]); u.send(:convert_locale_to_short_code);u.locale
    end

    attrs
  end

  # get user we can use to sync ms data
  # If admin is required, use admin or bust
  # If admin not required, try to first use admin, else 
  # check self for auth, then bust
  def microsoft_graph_sync_user(admin_required: false)

    if admin_required
      return self.company.admin_sync_user(provider: :microsoft_graph)
    elsif user = self.company.admin_sync_user(provider: :microsoft_graph)
      return user
    else
      self.authentications.microsoft_graph.present? ? user : nil      
    end

  end

  #return's back extension and mime type
  #usage:  extension, mime_type = determine_image_type(path)
  #since we only get raw binary no telling what the format
  #is Ergo I invoke unix file to determine it's mime type 
  
  def determine_image_type(temp_file_path)
    unix_file_type =  `file #{temp_file_path}`
    #IO.popen(["file", "--brief", "--mime-type", path], in: :close, err: :close) { |io| io.read.chomp }
    case(unix_file_type)
    when /jpe?g/i
      ['jpg', 'image/jpeg']
    when /png/i
      ['png', 'image/png']
    when /gif/i
      ['gif', 'image/png']
    else
      #return some unknown or have a default
    end
  end

  #transform raw binary into image uploaded attachment
  #using ruby tempfile and unix file command

  def build_attachment_from(raw_binary) 
    return nil unless raw_binary
    require 'tempfile'
    tmp = Tempfile.new('avatar')
    tmp.binmode
    tmp << raw_binary
    tmp.flush
    path = tmp.path
    tmp.rewind
    extension, mime_type = determine_image_type(path)
    img_params = {
      :filename => "avatar.#{extension}",
      :tempfile => tmp,
      :type => mime_type
    }
  end

  def microsoft_graph_client
    MicrosoftGraphClient.new(self.microsoft_graph_token, self)
  end

  def microsoft_graph_token
    self.authentications.microsoft_graph.try(:credentials).try(:token)
  end

  def microsoft_graph_admin?
    scopes = self.authentications.microsoft_graph.try(:oauth_scopes).try(:split, " ")
    scopes.map(&:downcase).include?("https://graph.microsoft.com/group.read.all") if scopes.present?
  end

  def set_outlook_identity_token(encrypted_token)
    outlook_decoder = Recognize::OutlookJwtDecoder.new(encrypted_token)
    outlook_decoder.validate

    if outlook_decoder.valid?
      self.update_column(:outlook_identity_token, outlook_decoder.unique_id)
    else
      Rails.logger.debug "Could not save outlook identity token: #{outlook_decoder.errors.join(", ")}"
    end

  end
end
