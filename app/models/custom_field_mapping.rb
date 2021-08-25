# DWF Example
# data = {
#  "Title": "extension_0ff998726dc54338a88172abed69cb11_title",
#  "Team": "extension_0ff998726dc54338a88172abed69cb11_team",
#  "Practice Area": "extension_0ff998726dc54338a88172abed69cb11_practicearea",
#  "Office Name": "extension_0ff998726dc54338a88172abed69cb11_physicalDeliveryOfficeName",
#  "Mail": "extension_0ff998726dc54338a88172abed69cb11_mail",
#  "Department": "extension_0ff998726dc54338a88172abed69cb11_department",
#  "Employee ID": "extension_0ff998726dc54338a88172abed69cb11_employeeNumber"
# }
# data.each {|k,v| CustomField.create(company_id: Company.where(domain: "dwf.law.not.real.tld").first.id, name: k, provider_id: v)}

# Custom Fields for a company are implemented in a way that the data is stored directly
# on the User model via columns :custom_field1, :custom_field2, :custom_field3
# And the metadata for each custom field is stored in the CustomField table and is specific to each to company
# This seems to be a practical approach with minimal overhead that doesn't require a separate table that
# needs to be joined in without also adding hard coded columns specific to each company onto the user table.
# The assumption is that the custom field data will always be a string, and not text or other data type
# See spec/models/custom_field_spec.rb for usage.
# NOTE: the magic of the custom field architecture will be added via app/models/concerns/custom_field_magic.rb
#       But essentially, its a basic module that adds methods to User and Company
class CustomFieldMapping < ActiveRecord::Base
  belongs_to :company

  validates :company_id, :key, :name, :provider_key, presence: true
  validates :mapped_to, inclusion: { in: Proc.new { mappable_user_attributes } }, allow_blank: true
  validates_uniqueness_of :key, :name, :provider_key, :mapped_to, scope: [:company_id], allow_blank: true, case_sensitive: true
  validates :provider_type, inclusion: { in: Proc.new { provider_types } }, allow_blank: true
  validates :provider_attribute_key, presence: true, if: -> { self.is_for_ms_graph_schema_extension? }

  attr_accessor :new_record_temporary_id

  MAPPABLE_USER_ATTRIBUTES = %w(birthday start_date job_title country department locale).freeze

  # https://docs.microsoft.com/en-us/answers/questions/171019/extension-attributes-for-azure-active-directory.html
  PROVIDER_TYPES = %w[ms_graph_schema_extension ad_connect_schema_extension].freeze

  def self.mappable_user_attributes
    MAPPABLE_USER_ATTRIBUTES
  end

  def self.provider_types
    PROVIDER_TYPES
  end

  def is_for_ms_graph_schema_extension?
    self.provider_type == "ms_graph_schema_extension"
  end
end
