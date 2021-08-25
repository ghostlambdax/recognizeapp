require 'will_paginate/array'
class CatalogsDatatable < DatatablesBase
  COLUMN_ATTRIBUTES = {
      0 => {orderable: false},
      2 => {orderable: false},
      4 => {orderable: false},
      5 => {orderable: false, title: ''},
      6 => {orderable: false, title: ''},
      7 => {orderable: false, title: ''}
  }

  COLUMN_TABLE_MAP = {
    "currency_symbol" => "currency_symbol",
    "currency_name" => "catalogs.currency",
    "roles" => "roles",
    "points_to_currency_ratio" => "catalogs.points_to_currency_ratio",
    "status" => "catalogs.is_enabled",
    "catalog_link" => "catalog_link",
    "redemptions_link" => "redemptions_link",
    "settings_link" => "settings_link"
  }.freeze

  def default_order
    "[[ 1, \"asc\" ]]"
  end

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def columns
    arr = column_table_map.keys
    arr.size.times.zip(arr).to_h
  end

  def namespace
    "catalogs"
  end

  def serializer
    CatalogSerializer
  end

  private

  def all_records
    company.catalogs
  end

  def filtered_records
    catalogs = all_records.includes(:company)
    search_value = params.dig(:search, :value)

    if search_value.present?
      currencies = get_matching_currency_codes(search_value)
      catalogs = catalogs.where("catalogs.currency like :search OR catalogs.points_to_currency_ratio like :search OR catalogs.currency in (:currencies)", search: "%#{search_value}%", currencies: currencies)
    end

    catalogs = catalogs.order("#{sort_columns_and_directions}")
    catalogs = catalogs.page(page).per_page(per_page)
    catalogs
  end

  def get_matching_currency_codes search_value
    Rewards::Currency.get_matching_currency_codes search_value
  end

  class CatalogSerializer < BaseDatatableSerializer

    attributes :currency_symbol, :currency_name, :roles, :points_to_currency_ratio, :status, :catalog_link, :redemptions_link, :settings_link

    def currency_symbol
      catalog.currency_prefix
    end

    def currency_name
      label = "#{catalog.currency} ( #{catalog.currency_info} )"
      link_to(label, rewards_dashboard_path(catalog))
    end

    def roles
      catalog.company_roles.map(&:name).join(", ")
    end

    def catalog_link
      context.link_to(
        _('Catalog'),
        context.company_admin_catalog_rewards_path(catalog),
        class: "button button-chromeless"
      )
    end

    def redemptions_link
      context.link_to(
        _('Redemptions'),
        context.company_admin_redemptions_path(catalog_id: catalog),
        class: "button button-chromeless"
      )
    end
    
    def settings_link
      context.link_to(
        _('Settings'),
        context.edit_company_admin_catalog_path(catalog),
        class: "button button-chromeless"
      )
    end

    def status
      catalog.is_enabled? ? I18n.t("dict.active") : I18n.t("dict.disabled")
    end

    def catalog
      @object
    end
  end
end
