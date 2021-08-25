# frozen_string_literal: true

module IntervalNotificationRunner
  module CoreModule
    # class methods
    module ConfigMethods
      # interface to specify hour to run (required config)
      def run_at_hour(hour, opts = {})
        # need to fetch :if value via opts hash because it is a keyword
        if (invalid_opts = opts.keys - [:if]).present?
          raise ArgumentError, "IntervalNotificationRunner: invalid config opts: #{invalid_opts}"
        end

        custom_run_condition = opts[:if]
        unless hour.is_a?(Integer)
          raise ArgumentError, "IntervalNotificationRunner: invalid run_at_hour() arg: should be an integer, not #{hour.class}"
        end

        unless custom_run_condition.nil? || custom_run_condition.is_a?(Proc)
          raise ArgumentError, "IntervalNotificationRunner: the :if option for run_at_hour() only supports a Proc, but #{custom_run_condition.class} was provided"
        end

        # note: accessors for these class attrs are defined in the base module file
        self.hour_to_run = hour
        self.custom_run_condition = custom_run_condition
      end
    end
  end
end
