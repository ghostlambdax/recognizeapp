# frozen_string_literal: true

class RewardsTransactionsAdminDatatable < RewardsTransactionsDatatable

  COLUMN_TABLE_MAP = {
    "date" => "created_at",
    "company" => "companies.domain",
    "credit" => "amount",
    "debit" => "amount",
    "catalog" => "catalog",
    "description" => "description"
  }.freeze

  def base_records
    Rewards::FundsTxn
      .joins(funds_account: :company)
      .where.not(funds_accounts: {recognize_admin: true})
  end

  def columns
    {
      0 => "date",
      1 => "company",
      2 => "description",
      3 => "catalog",
      4 => "credit",
      5 => "debit"
    }
  end
end
