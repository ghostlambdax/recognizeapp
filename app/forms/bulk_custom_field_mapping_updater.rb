class BulkCustomFieldMappingUpdater
  include ActiveModel::Model

  attr_reader :company, :cfms_to_create, :cfms_to_update, :params
  validate :all_cfms_are_valid

  UPDATEABLE_ATTRS = [:name, :mapped_to, :provider_key, :provider_type, :provider_attribute_key, :key]

  def initialize(company)
    @company = company
  end

  def update(_params)
    @params = _params
    setup_cfms_to_create
    setup_cfms_to_update

    if valid?
      CustomFieldMapping.transaction do
        cfms_to_create.map(&:save!)
        cfms_to_update.map(&:save!)
      end
      return true
    else
      return false
    end
  end

  def persisted?
    true
  end

  def self.attributes_for_json
    [:created_cfms, :updated_cfms]
  end

  def created_cfms
    return [] unless valid?

    cfms_to_create.select(&:persisted?).map do |cfm|
      {
        id: cfm.id,
        key: cfm.key,
        temporary_id: cfm.new_record_temporary_id,
        name: cfm.name,
        provider_key: cfm.provider_key,
        mapped_to: cfm.mapped_to
      }
    end
  end

  def updated_cfms
    valid? ? cfms_to_update.map{ |cfm| {id: cfm.id }.merge(cfm_attributes_for_row(cfm)) } : []
  end

  private

  def cfm_attributes_for_row(cfm)
    cfm.attributes.slice(*UPDATEABLE_ATTRS.map(&:to_s))
  end

  def setup_cfms_to_create
    set = params.inject([]) do |array, (_id, cfm_params)|
      if cfm_params[:create].present? && cfm_params[:create] == "1"
        cfm = custom_field_mapping_scope.new(cfm_params.slice(*UPDATEABLE_ATTRS))
        cfm.new_record_temporary_id = cfm_params[:id]
        array << cfm
      end
      array
    end
    @cfms_to_create = CustomFieldMappingCollection.new(set)
  end

  def setup_cfms_to_update
    set = params.inject([]) do |array, (_id, cfm_params)|
      if cfm_params[:update].present? && cfm_params[:update] == "1"
        cfm = custom_field_mapping_scope.find(cfm_params[:id])
        cfm.assign_attributes(cfm_params.slice(*UPDATEABLE_ATTRS))
        # for nil to "" change
        cfm.changes.each do |k, v|
          cfm.clear_attribute_changes([k]) if v[0].to_s == v[1].to_s
        end
        array << cfm if cfm.changed?
      end
      array
    end
    @cfms_to_update = CustomFieldMappingCollection.new(set)
  end

  def all_cfms_are_valid
    if (cfms_to_update && !cfms_to_update.valid?) || (cfms_to_create && !cfms_to_create.valid?)
      errors.add(:base, "Save did not complete due to the errors below.")
      # hack to get json resource to report errors on the respective collection
      errors.add(:cfms_to_create, "") unless cfms_to_create.valid?
      errors.add(:cfms_to_update, "") unless cfms_to_update.valid?
    end
  end

  def custom_field_mapping_scope
    company.custom_field_mappings.custom_field_mapping
  end

  class CustomFieldMappingCollection < Array
    def valid?
      @valid ||= each(&:valid?) && !errors.present?
    end

    def errors
      @errors ||= inject({}){|hash, cfm|
        id = cfm.persisted? ? cfm.to_param : cfm.new_record_temporary_id #FIXME
        hash[id] = cfm.errors if cfm.errors.present?
        hash
      }
    end
  end
end
