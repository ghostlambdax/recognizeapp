require 'will_paginate/array'
# This is really a super-admin thang...
class CompaniesDatatable < DatatablesBase
  include DateTimeHelper

  COMPANY_ATTRIBUTES = {
    "id" => "companies.id",
    "domain" => "companies.domain",
    "subscription" => "subscription"
  }

  REPORT_ATTRIBUTES = Report::Companies::REPORT_NAMES.inject({}){|map, rpt| map[rpt.to_s] = rpt.to_s;map}
  EXTRA_COLUMNS = {"actions" => "actions"}
  COLUMN_TABLE_MAP = COMPANY_ATTRIBUTES.merge(REPORT_ATTRIBUTES).merge(EXTRA_COLUMNS)

  DEFAULT_COLUMN_ATTRIBUTES = COLUMN_TABLE_MAP.inject({}){|map,(k,v)| map[COLUMN_TABLE_MAP.keys.index(k)] = {orderSequence: '[\'desc\']'};map}
  COLUMN_ATTRIBUTES = DEFAULT_COLUMN_ATTRIBUTES.deep_merge({
    1 => {orderable: false},
    2 => {orderable: false}
  })

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      recordsTotal: all_records.length,
      recordsFiltered: all_records.length,
      data: data
    }
  end

  def all_records
    @report = Report::Companies.all(
      order: sort_columns.first, 
      page: page,
      per_page: per_page,
      search: params[:search] && params[:search][:value])

    companies = @report.companies
    return companies
  end

  def columns
    arr = column_table_map.keys
    columns = arr.size.times.zip(arr).to_h
    return columns
  end

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def filtered_records
    self.all_records
  end

  def namespace
    'companies-datatable'
  end

  def serializer
    CompanySerializer
  end

  class CompanySerializer < BaseDatatableSerializer
    attributes *CompaniesDatatable::COLUMN_TABLE_MAP.keys
    CompaniesDatatable::COLUMN_TABLE_MAP.keys.each do |meth_name|
      define_method(meth_name) do
        object.send(meth_name)
      end
    end

    def domain
      link_to object.domain, admin_company_path(object.domain)
    end

  end
end