module CustomFieldMappingsHelper
  def build_custom_field_mapping(company, key, opts = {})
    new_cfm = company.custom_field_mappings.custom_field_mapping.new(key: key)
    if opts[:provision_temporary_id]
      temporary_id = SecureRandom.random_number(a_big_number = 10**50)
      new_cfm.id = temporary_id
    end
    new_cfm
  end

  def find_or_build_custom_field_mapping(company, key, opts = {})
    persisted_cfm = company.custom_field_mappings.get(key: key)
    persisted_cfm || build_custom_field_mapping(company, key, opts)
  end
end
