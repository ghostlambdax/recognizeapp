module Rewards
  class FundsAccountService

    #
    # convenience method to handle the funds_account business logic
    # for a redemption.  
    # 
    # The redemption parameter must respond_to amount
    # and must have a polymorphic relation to funds_txns similar to:
    #     has_many :funds_txns, as: :funds_txnable
    #
    # It will transfer the amount of the redemption from the specified
    # account to the first funds_account that is marked as a recognize
    # admin funds account
    #
    # TODO:  Add support for tracking provider balance
    #   - Provider charge is in redemption object
    #   - Add new FundsAccount for providers  (redemption.provider.funds_account)
    #   - Debit provider charge from Provider FundsAccount as part of transaction
    def self.redemption(account, redemption)

      # make sure we get a valid redemption so we catch it here instead of lower down
      raise 'redemption must have the association has_many :funds_txns, as: :funds_txnable' unless redemption.respond_to?('funds_txns')
      raise 'redemption must respond_to amount' unless redemption.respond_to?('amount')

      # get our admin account before we start a transaction
      admin_acct = self.get_recognize_admin_account
      raise "No rails_admin funds_account is set!  Cannot process redemption in FundsAccountService.redemption" if admin_acct.nil?

      # now that we have our admin account, start our transaction and process debit/credit
      Rewards::FundsAccount.transaction do
        debit_adjustment = account.debit(redemption)
        credit_adjustment = admin_acct.credit(redemption)

        # do a noop with debit_adjustment so it gets returned outside of the transaction
        debit_adjustment
      end
    end

    #
    # convenience method to deposit a StripeCharge to a funds_account.  
    # It will do the following:
    #   - deposit full amount into customer account
    #   - debit transaction charge from customer account
    #   - credit transaction charge to Recognize account
    #
    def self.deposit_stripe_charge(account, stripe_charge)

      # get our admin account before we start a transaction
      admin_acct = self.get_recognize_admin_account

      Rewards::FundsAccount.transaction do
        adj = Rewards::ServiceChargeFundsAdjustment.create(amount: account.service_charge,
                                                  adjustment_type: "service_charge",
                                                  comment: "Service charge for deposit via credit card")

        # credit the funds
        account.credit(stripe_charge)

        # do our service charge
        # call credit with the FundsAccountManualAdjustment base class instead
        # of ServiceChargeFundsAdjustment so we don't break the funds_txnable
        # polymorphic relationship
        account.debit(adj.becomes(adj.class.base_class))
        admin_acct.credit(adj.becomes(adj.class.base_class))

        # do a noop with adj so it gets returned outside of the transaction
        adj
      end
    end

    #
    # convenience method to apply a check deposit to a funds_account
    # It will do the following:
    #   - deposit full amount into customer account
    #   - debit transaction charge from customer account
    #   - credit transaction charge to Recognize account
    #
    def self.deposit_check(account, amount, comment)

      # get our admin account before we start a transaction
      admin_acct = self.get_recognize_admin_account

      Rewards::CheckFundsAdjustment.transaction do
        adj = Rewards::CheckFundsAdjustment.create(amount: amount, comment: comment,
                                          adjustment_type: "credit")

        # call credit with the FundsAccountManualAdjustment base class instead
        # of CheckFundsAdjustment so we don't break the funds_txnable
        # polymorphic relationship
        account.credit(adj.becomes(adj.class.base_class))

        if account.service_charge?
          service_charge_adj = Rewards::ServiceChargeFundsAdjustment.create(amount: account.service_charge,
                                                                   adjustment_type: "service_charge",
                                                                   comment: "Service charge for deposit via credit card")

          # do our service charge
          # call credit with the FundsAccountManualAdjustment base class instead
          # of ServiceChargeFundsAdjustment so we don't break the funds_txnable
          # polymorphic relationship
          account.debit(service_charge_adj.becomes(service_charge_adj.class.base_class))
          admin_acct.credit(service_charge_adj.becomes(service_charge_adj.class.base_class))
        end

        # do a noop with adj so it gets returned outside of the transaction
        adj
      end
    end

    #
    # convenience method to apply a wire transfer to a funds_account
    # It will do the following:
    #   - deposit full amount into customer account
    #   - debit transaction charge from customer account
    #   - credit transaction charge to Recognize account
    #
    def self.deposit_wire(account, amount, comment)

      # get our admin account before we start a transaction
      admin_acct = self.get_recognize_admin_account

      Rewards::WireFundsAdjustment.transaction do
        adj = Rewards::WireFundsAdjustment.create(amount: amount, comment: comment,
                                         adjustment_type: "credit")

        # call credit with the FundsAccountManualAdjustment base class instead
        # of CheckFundsAdjustment so we don't break the funds_txnable
        # polymorphic relationship
        account.credit(adj.becomes(adj.class.base_class))

        if account.service_charge?
          service_charge_adj = Rewards::ServiceChargeFundsAdjustment.create(amount: account.service_charge,
                                                                   adjustment_type: "service_charge",
                                                                   comment: "Service charge for deposit via credit card")

          # do our service charge
          # call credit with the FundsAccountManualAdjustment base class instead
          # of ServiceChargeFundsAdjustment so we don't break the funds_txnable
          # polymorphic relationship
          account.debit(service_charge_adj.becomes(service_charge_adj.class.base_class))
          admin_acct.credit(service_charge_adj.becomes(service_charge_adj.class.base_class))
        end
        
        # do a noop with adj so it gets returned outside of the transaction
        adj
      end
    end

    #
    # Manually credit a funds_account
    #  
    def self.manual_credit(account, amount, comment)
      # wrap it all in a transaction so that we are
      # guaranteed it all succeeds or is rolled back
      Rewards::FundsAccountManualAdjustment.transaction do
        adj = Rewards::FundsAccountManualAdjustment.create(amount: amount, comment: comment, 
                                                  adjustment_type: "credit")
        account.credit(adj)

        # do a noop with adj so it gets returned outside of the transaction
        adj
      end
    end

    #
    # Manually debit a funds_account
    #  
    def self.manual_debit(account, amount, comment)
      # wrap it all in a transaction so that we are
      # guaranteed it all succeeds or is rolled back
      Rewards::FundsAccountManualAdjustment.transaction do
        adj = Rewards::FundsAccountManualAdjustment.create(amount: amount, comment: comment,
                                                  adjustment_type: "debit")
        account.debit(adj)

        # do a noop with adj so it gets returned outside of the transaction
        adj
      end
    end

    private

    def self.get_recognize_admin_account
      # get our admin account before we start a transaction
      admin_acct = Rewards::FundsAccount.recognize_admin_accts.first

      return admin_acct
    end
  end
end