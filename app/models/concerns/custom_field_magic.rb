# For this custom field architecture, we want to avoid having join tables for performance reasons
# As such we need to store the data directly on User model, but we don't want to serialize
# and we don't want to create company specific columns. 
# Instead, we will add general columns to the User model in the form of custom_field1, custom_field2..custom_fieldN
# This is essentially creating general slots on the User model that each Company can define. 
# The metadata of what each custom_field1, custom_field2, etc means is defined on the CustomField model
#
# This approach utilizes a key, and provider_key approach where
#   + key - is the recognize custom field key. Eg, custom_field1, custom_field2. 
#   + provider_key - is a unique identifier for the provider's custom field datum.
#
# The provider key serves two purposes: 1) it allows the name of the field that is 
# displayed in web interface to change and 2) it serves as a key for lookup in the company's sync. 
# At the moment, Recognize will support 6 custom fields. 
# The "key" field also serves two purposes 1) it allows the link to the custom_field1, custom_field2
# 2) But also, it allows added data that comes from a companies custom field in the sync and apply to it 
# a standard User model field. The standard case for this is Employee ID. 
module CustomFieldMagic

  module CompanyConcern
    extend ActiveSupport::Concern

    included do
      has_many :custom_field_mappings, inverse_of: :company, dependent: :destroy
    end

    # returns metadata/mapping of the custom_field1, custom_field2, custom_fieldN
    # specified for a company
    def custom_field_mappings
      CustomFieldMapping.new(self, super)
    end
  end

  module UserConcern
    # returns data class for setting and retrieving
    # values based on provider key
    def custom_fields
      CustomFieldData.new(self)
    end
  end

  class CustomFieldMapping
    attr_reader :company, :custom_field_mapping
    delegate :blank?, :present, :each, :inject, :map, to: :custom_field_mapping

    def initialize(company, custom_field_mapping)
      @company = company
      @custom_field_mapping = custom_field_mapping
    end

    def set(key, name, provider_key)
      cf = custom_field_mapping.find_or_initialize_by(key: key)
      cf.name = name
      cf.provider_key = provider_key
      cf.save!
    end

    def get(opts)
      custom_field_mapping.loaded? ?
        custom_field_mapping.detect{|cfm| opts.all?{|k,v| cfm.send(k).to_s == v.to_s}} :
        custom_field_mapping.find_by(opts)
    end

    def microsoft_graph_query_attributes
      provider_keys
    end

    def provider_keys
      custom_field_mapping.map(&:provider_key)
    end

    def any?
      User.custom_field_attributes.any? do |custom_field_key|
        get(key: custom_field_key)
      end      
    end
  end

  class CustomFieldData
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def custom_field_mapping(provider_key)
      user.company.custom_field_mappings.get(provider_key: provider_key)
    end

    def set(provider_key, value)
      custom_field = custom_field_mapping(provider_key)
      user.update_column(custom_field.key, value)
    end

    def get(provider_key)
      custom_field = custom_field_mapping(provider_key)
      user.send(custom_field.key)
    end

    def to_h(key_type: :name)
      user.company.custom_field_mappings.inject({}) do |hash, mapping|
        provider_key = mapping.provider_key
        key = mapping.send(key_type)
        hash[key] = get(provider_key)
        hash
      end
    end
  end
end
