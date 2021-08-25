module IntervalNotificationRunner
  module CoreModule
    module InstanceMethods
      # note: attr readers for these variables are defined in the base module file
      def initialize(company_id, reference_time: Time.current, dry_run: false, **custom_run_opts)
        company_id = company_id.id if company_id.class == Company
        @company = Company.find(company_id)
        @reference_time = reference_time
        @dry_run = dry_run
        # this variable is for manual use by client classes, eg. for custom interval / shift for report
        @custom_run_opts = custom_run_opts

        # Note: this is already checked in the class-level :run, but checking here additionally to cover manual init
        self.class.validate_custom_params!(custom_run_opts)
      end

      def run
        deliverer = DeliveryHandler.new(self, recipients, dry_run, recipient_email_setting_filter)
        deliverer.invoke
      end

      #
      # Methods to be defined by client classes
      #
      def recipients
        raise AbstractMethodError, :recipients
      end

      def email_for_recipient(_recipient)
        raise AbstractMethodError, :email_for_recipient
      end

      # optional setting hash for filtering recipients by specific :email_setting attributes
      # this hash is merged & queried together with the global unsubscribe attr
      def recipient_email_setting_filter
        {}
      end
    end
  end
end
