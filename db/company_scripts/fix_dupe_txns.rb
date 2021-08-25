$debug = false
suffix = Rails.env.development? ? ".not.real.tld" : ""
RollbackException = Class.new(Exception)

redemption_ids_with_dupe_txns = Rewards::FundsTxn.where(funds_txnable_type: "Redemption").group(:funds_txnable_id).having("count_all > 2").count.keys
redemptions = Redemption.where(id: redemption_ids_with_dupe_txns)

# for testing Pinella
pinella = Company.where(domain: "pinellascomputers.com"+suffix).first
pinella_redemptions = redemptions.where(company_id: pinella.id)


redemptions_to_clean = pinella_redemptions

def clean_redemptions_of_dupe_txns(redemptions)  
  begin
    Redemption.transaction(requires_new: true) do
      affected_company_ids = redemptions.map(&:company_id).uniq
      companies = Company.where(id: affected_company_ids)
      log "Cleaning up dupe txns for: #{companies.map(&:domain).join(',')}"

      grouped_redemptions = redemptions.group_by(&:company_id)
      grouped_redemptions.each do |company_id, company_redemptions|
        log " ------------------------------------------------- "
        company = Company.find(company_id)
        log_company_redemption_info(company, company_redemptions, :before)
        log "Processing: #{company.domain}"
        company_redemptions.each do |r|
          clean_redemption_of_dupe_txn(r)
        end

        company.primary_funding_account.recalculate_balance!
        Rewards::FundsAccount.recognize_admin_accts.first.recalculate_balance!

        log_company_redemption_info(company, company_redemptions, :after)
        log " ------------------------------------------------- "
      end
      raise RollbackException if $debug
    end
  rescue RollbackException => e
    log "Rolling back"
  end

end

def clean_redemption_of_dupe_txn(redemption)
  domain = redemption.company.domain

  #log "[c:#{domain}][u:#{redemption.user.email}][r:#{redemption.id}] Beginning cleanup of dupe funds txns"

  funds_txns = redemption.funds_txns
  credit_funds_txns = funds_txns.select{|f| f.txn_type == 'credit'}
  debit_funds_txns = funds_txns.select{|f| f.txn_type == 'debit'}

  credit_funds_txns_to_destroy = credit_funds_txns[1..credit_funds_txns.length-1] # leave one
  debit_funds_txns_to_destroy = debit_funds_txns[1..debit_funds_txns.length-1] # leave one
  
  before_total_credit = credit_funds_txns.sum(&:amount)
  before_total_debit = debit_funds_txns.sum(&:amount)

  credit_to_destroy = credit_funds_txns_to_destroy.sum(&:amount)
  debit_to_destroy = debit_funds_txns_to_destroy.sum(&:amount)

  credit_funds_txns_to_destroy.map(&:destroy)
  debit_funds_txns_to_destroy.map(&:destroy)
  #log "[c:#{domain}][u:#{redemption.user.email}][r:#{redemption.id}] Redemption:  #{redemption.reward.title} - #{redemption.value_redeemed} - #{redemption.created_at}"


  log "\t[c:#{domain}][u:#{redemption.user.email}][r:#{redemption.id}] Total Txns: #{funds_txns.length} (C:$#{before_total_credit} - D:$#{before_total_debit}) - Removing: (C:#{credit_funds_txns_to_destroy.length} - D:#{debit_funds_txns_to_destroy.length}) (C:$#{credit_to_destroy} - $#{debit_to_destroy})"

end

def log(msg)
  Rails.logger.debug "[DUPETXNFIX]#{msg}"
end

def log_company_redemption_info(company, company_redemptions, before_or_after)
  company.reload
  domain = company.domain
  all_redemptions = company.redemptions

  if before_or_after == :after
    # ensures a full reload of associations
    company_redemptions = company_redemptions.map{|cr| Redemption.find(cr.id) }
  end


  unique_credit_funds_txns = company_redemptions.map{|r| r.funds_txns.select{|f| f.txn_type == 'credit'}.first}.flatten
  unique_debit_funds_txns = company_redemptions.map{|r| r.funds_txns.select{|f| f.txn_type == 'debit'}.first}.flatten

  # funds_txns_to_destroy = company_redemptions.map{|r| r.funds_txns[0..r.funds_txns.length-2]}.flatten
  credit_txns_to_destroy = company_redemptions.map{|r| 
    credits = r.funds_txns.select{|f| f.txn_type == 'credit'}
    credits[1..credits.length - 1]
  }.flatten
  debit_txns_to_destroy = company_redemptions.map{|r| 
    debits = r.funds_txns.select{|f| f.txn_type == 'debit'}
    debits[1..debits.length - 1]
  }.flatten

  value_of_unique_credit_funds_txns = unique_credit_funds_txns.sum(&:amount)
  value_of_unique_debit_funds_txns = unique_debit_funds_txns.sum(&:amount)

  value_of_non_unique_credit_funds_txns = credit_txns_to_destroy.sum(&:amount)
  value_of_non_unique_debit_funds_txns = debit_txns_to_destroy.sum(&:amount)

  value_of_redemptions = company_redemptions.sum(&:value_redeemed)

  deposit_value = Rewards::FundsTxn.where(funds_account_id: company.primary_funding_account.id, txn_type: "credit").sum(:amount)
  redeemed_value = Rewards::FundsTxn.where(funds_account_id: company.primary_funding_account.id, txn_type: "debit").sum(:amount)
  diff_btw_deposit_and_redeemed = deposit_value - redeemed_value
  primary_funding_account_balance = company.primary_funding_account.balance
  proper_balance = deposit_value - all_redemptions.sum(&:value_redeemed)

  recognize_admin_acct = Rewards::FundsAccount.recognize_admin_accts.first
  recognize_balance = recognize_admin_acct.balance

  log "[c:#{domain}] - Deposited Total: #{deposit_value}"
  log "[c:#{domain}] - Redeemed Total based on FundsTxns (should be == to value of redemptions): #{redeemed_value}"

  log "[c:#{domain}] - Proper Total value of ALL redemptions (based on the redemptions themselves): #{all_redemptions.sum(&:value_redeemed)}"
  log "[c:#{domain}] - Proper Total value of redemptions that had dupe txns (based on the redemptions themselves): #{value_of_redemptions}"

#  log "[c:#{domain}] - Diff b/w deposited and redeemed: #{diff_btw_deposit_and_redeemed}"

  log "[c:#{domain}] - Value of unique credit funds txns (to remain in Recognize balance): #{value_of_unique_credit_funds_txns}"
  log "[c:#{domain}] - Value of unique debit funds txns (to continue to be debited from Company balance): #{value_of_unique_debit_funds_txns}"

  log "[c:#{domain}] - Value of non unique credit funds txns (#{before_or_after == :before ? 'To be destroyed and subtracted from Recognize' : ''}): #{value_of_non_unique_credit_funds_txns}"
  log "[c:#{domain}] - Value of non unique debit funds txns (#{before_or_after == :before ? 'To be destroyed and given back to Company' : ''}): #{value_of_non_unique_debit_funds_txns}"


  log "[c:#{domain}] - Company's Primary Funding Account Balance: #{primary_funding_account_balance}"
  log "[c:#{domain}] - Proper balance should be: #{proper_balance}"
  log "[c:#{domain}] - Recognize balance: #{recognize_balance}"


end

clean_redemptions_of_dupe_txns(redemptions_to_clean)