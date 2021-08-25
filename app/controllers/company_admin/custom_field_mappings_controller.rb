# frozen_string_literal: true

class CompanyAdmin::CustomFieldMappingsController < CompanyAdmin::BaseController
  def show
    @bulk_custom_field_mapping_updater = BulkCustomFieldMappingUpdater.new(@company)
  end

  def update
    @bulk_custom_field_mapping_updater = BulkCustomFieldMappingUpdater.new(@company)
    @bulk_custom_field_mapping_updater.update(bulk_custom_field_mapping_updater_params)
    respond_with @bulk_custom_field_mapping_updater
  end

  private
  def bulk_custom_field_mapping_updater_params
    allowed_attrs = BulkCustomFieldMappingUpdater::UPDATEABLE_ATTRS + %i[id create update]

    params
      .require(:bulk_custom_field_mapping_updater).to_unsafe_h
      .select { |k, _v| k =~ /\A\d+\z/ }
      .transform_values do |attr_hash|
      attr_hash
        .slice(*allowed_attrs)
        .select { |_k, val| val.is_a?(String) }
    end
  end
end
