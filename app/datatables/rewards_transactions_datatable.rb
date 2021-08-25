# NOTE: if this class gets upgraded to a Litatable
#       Be sure to update RewardsTransactionsAdminDatatable as well
require 'will_paginate/array'
class RewardsTransactionsDatatable < DatatablesBase
  include DateTimeHelper

  COLUMN_TABLE_MAP = {
    "date" => "created_at",
    "credit" => "amount",
    "debit" => "amount",
    "catalog" => "catalog",
    "description" => "description",
  }

  def base_records
    Rewards::FundsTxn
      .joins(:funds_account)
      .where("funds_accounts.company_id = ?", company.id)
      .where.not(funds_accounts: {recognize_admin: true})
  end

  def all_records
    funds_txns = base_records
    funds_txns = funds_txns.where(catalog_id: Integer(params[:catalog_id])) if params[:catalog_id].present?
    funds_txns = funds_txns.order(sort_columns_and_directions) if params[:order].present?
    funds_txns
  end

  def columns
    {
      0 => "date",
      1 => "description",
      2 => "catalog",
      3 => "credit",
      4 => "debit"
    }
  end

  COLUMN_ATTRIBUTES = {
    4 => { title: "Amount deposited" },
    5 => { title: "Amount withdrawn" }
  }.freeze

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def filtered_records
    set = self.all_records_filtered_by_date_range(table: :funds_txns)

    if params[:search].present? && params[:search][:value].present?
      tokens = params[:search][:value].split(" ")
      currency_tokens = Rewards::Currency.get_matching_currency_codes(tokens)
      tokens.reject!{|t| currency_tokens.include?(t) }

      # catalogs = catalogs.where("catalogs.currency like :search OR catalogs.points_to_currency_ratio like :search OR catalogs.currency in (:currencies)", search: "%#{search_value}%", currencies: currencies)

      q = "%#{tokens.join(" ")}%"

      if tokens.present?
        if company.present?
          set = set.where("funds_txns.description like ? OR amount like ?", q, q)
        else
          set = set.where("funds_txns.description like ? OR amount like ? OR companies.domain like ?", q, q, q)
        end
      end

      if currency_tokens.present?
        set = set.joins(:catalog).where(catalogs: {currency: currency_tokens})
      end
    end

    set.paginate(page: page, per_page: per_page)
  end

  def dt_columns_that_require_complex_sort
    %w[catalog debit credit]
  end

  def requires_complex_sort?(column_name)
    dt_columns_that_require_complex_sort.include? column_name
  end

  #
  # Hack!
  # Since both 'credit' and 'debit' column in the datatable conditionally represent the `amount` column in the database,
  # sorting by these datatable columns is not simple. The following method tries to do the sort.
  #
  def complex_sort(column_name, direction)
    dt_column_name_txn_type_map = { "debit" => "debit", "credit" => "credit" }
    txn_type_being_sorted = dt_column_name_txn_type_map[column_name]

    # Here we use the maximum value of 'amount' in the relevant table to ensure that we have weighted the sorting correctly.
    max_funds_txn_amount = base_records.maximum("amount")
    weight_1, weight_2 = direction == "desc" ? [max_funds_txn_amount, 0] : [0, max_funds_txn_amount]
    sql_order_str = "
        CASE
          WHEN txn_type = '#{txn_type_being_sorted}' THEN #{weight_1} + amount
          WHEN txn_type <> '#{txn_type_being_sorted}' THEN #{weight_2} + amount
        END
    "
    sql_order_str
  end

  # method override
  def sort_columns
    sc = columns.values_at(*order_params.map { |p| p["column"].to_i })
    sc.map do |c|
      if requires_complex_sort?(c)
        c_index = columns.detect { |_index, column_name| column_name == c }.first
        c_direction = order_params.detect { |p| p["column"] == c_index.to_s }["dir"]
        complex_sort(c, c_direction)
      else
        column_table_map[c].presence || c
      end
    end
  end

  def namespace
    'transactions'
  end

  def serializer
    RewardsTransactionsSerializer
  end

end
