require 'active_support/concern'
module Approval
  #
  # This module provides functionalities for entities with stateful approval workflow; Redemption, CompletedTasks, etc.
  #
  # Requires:
  #   - :status_id field in db table of the client class.
  #   - Enabling PaperTrail in relevant controller overriding PaperTrail's method `paper_trail_enabled_for_controller`.
  #       def paper_trail_enabled_for_controller
  #         true
  #       end
  #
  # Provides the following to the client client class. (See code below for more details)
  #
  #   # paper_trail versioning for changes in the `status_id` column
  #     - object.state_last_updated_by            # returns timestamp for the last status update
  #     - object.state_last_updated_at            # returns user who authored the last status update
  #
  #   #`object.current_paper_trail_user`          # returns the current user(set by paper trail)
  #
  #   # state interrogators using state names dynamically
  #     - object.approved? , object.pending? and so on if possible states are :pending, :approved, and so on.
  #
  #   - object.set_status!(status_symbol)          # changes the status, and performs after and before actions
  #     - before_set_status(_old_state, _new_state) # this acts similarly (but not exactly) as a before-hook
  #     - after_set_status(_old_state, _new_state) # this acts similarly (but not exactly) as an after-hook
  #
  #   - object.status                               # returns the current status name
  #   - object.status_label                         # returns the current status label
  #
  module Workflow
    InvalidStatusTransitionException = Class.new(Exception)

    extend ActiveSupport::Concern

    included do
      has_paper_trail only: [:status_id]

      before_validation { self.class.check_presence_of_required_workflow_opts }
      before_validation :set_default_status, on: :create
      before_validation :normalize_blank_comment_to_nil

      before_save :eavesdrop_on_status_change

      validates :status_id, inclusion: { in: :approval_state_ids }
      validate :state_transition_is_valid, if: :status_id_changed?

      class_attribute :approval_state_ids, :approval_opts
    end

    # START- ClassMethods

    module ClassMethods
      def approval_workflow_states(states, opts = {})
        setup_options(opts)
        setup_states(states)
      end

      def approval_workflow(opts = {})
        setup_options(opts)
      end

      def setup_states(states)
        validate_states(states)
        self.approval_state_ids = states.map { |state| states_klass.id_from_name(state) }
        setup_state_interrogators
      end

      def setup_options(opts)
        validate_opts(opts)
        self.approval_opts ||= {}
        self.approval_opts.merge!(opts)
      end

      def setup_state_interrogators
        self.approval_state_ids.each do |state_id|
          state_name = states_klass.name_from_id(state_id)
          method_name = "#{state_name}?"
          next if respond_to?(method_name)
          define_method(method_name) do
            status_id == state_id
          end
        end
      end

      def states_klass
        self.approval_opts[:states_klass]
      end

      def default_comment_field
        :approval_comment
      end

      def comment_field
        self.approval_opts[:comment_field] || default_comment_field
      end

      def check_presence_of_required_workflow_opts
        missing_required_opts_keys = required_opts_keys - self.approval_opts.keys
        return if missing_required_opts_keys.blank?
        missing_opts_keys_stringified = missing_required_opts_keys.map { |k| ":#{k}" }.join(", ")
        raise ArgumentError, "Missing required options! #{missing_opts_keys_stringified}"
      end

      private

      def supported_opts_keys
        optional_opts_keys + required_opts_keys
      end

      def optional_opts_keys
        %i[comment_field]
      end

      def required_opts_keys
        %i[default possible_state_transitions states_klass]
      end

      def validate_states(states)
        return if states.is_a?(Array)
        raise ArgumentError, "The first parameter - states - is supposed to be an array of states' symbols"
      end

      def validate_opts(opts)
        unsupported_opts_keys = opts.keys - supported_opts_keys
        return if unsupported_opts_keys.blank?
        unsupported_opts_keys_stringified = unsupported_opts_keys.map { |k| ":#{k}" }.join(", ")
        raise ArgumentError, "Unsupported options! #{unsupported_opts_keys_stringified}"
      end
    end

    # END - ClassMethods

    # START - InstanceMethods

    def state
      states_klass.find(self.status_id)
    end

    def status
      state&.name
    end

    def status_label
      state&.i18n_long_name
    end

    def status_name
      state&.name
    end

    def state_last_updated_by
      return nil if self.versions.blank?
      User.find_by(id: self.versions.last.whodunnit)
    end

    def state_last_updated_at
      return nil if self.versions.blank?
      self.versions.last.created_at
    end

    def current_paper_trail_user
      User.find(PaperTrail.request.whodunnit)
    end

    def set_status!(new_state)
      old_state = self.status
      raise InvalidStatusTransitionException unless valid_state_transition?(old_state, new_state)

      before_set_status(old_state, new_state)

      self.status_id = states_klass.id_from_name(new_state)

      return unless self.save

      after_set_status(old_state, new_state)
    end

    def before_set_status(_old_state, _new_state)
      # The client class can implement this method but is optional to do so.
      # If implemented, it is called very similarly (but not exactly) as a before-hook to `set_status` method.
    end

    def after_set_status(_old_state, _new_state)
      # The client class can implement this method but is optional to do so.
      # If implemented, it is called very similarly (but not exactly) as an after-hook to `set_status` method.
    end

    def status_changed_to?(state_name)
      @status_change.present? && self.send("#{state_name}?")
    end

    private

    def state_transition_is_valid
      old_state = states_klass.name_from_id(status_id_was)
      new_state = states_klass.name_from_id(status_id)
      return if valid_state_transition?(old_state, new_state)

      raise InvalidStatusTransitionException
    end

    def set_default_status
      self.status_id ||= default_state_id
    end

    def default_state_id
      states_klass.id_from_name(default_state)
    end

    def default_state
      default_state_in_opts = self.class.approval_opts[:default]
      default_state_in_opts.is_a?(Proc) ? self.instance_eval(&default_state_in_opts) : default_state_in_opts
    end

    def possible_state_transitions
      default_state_transition = { from: nil, to: default_state }
      self.approval_opts[:possible_state_transitions] + [default_state_transition]
    end

    def valid_state_transition?(old_state, new_state)
      transition_state = { from: old_state, to: new_state }
      possible_state_transitions.include? transition_state
    end

    # Submitting a form that has input field for `comment` without any comment content will send in an empty string in
    # the parameters, which then saves to the db as empty string. Avoid it by making blank comments nil.
    def normalize_blank_comment_to_nil
      comment_field = self.class.comment_field
      return unless self.has_attribute?(comment_field) # Not all client class may have comment field.
      return if self[comment_field].present?
      self[comment_field] = nil
    end

    def states_klass
      self.class.states_klass
    end

    #
    # Inspired by dhh. (https://www.youtube.com/watch?v=m1jOWu7woKM)
    # Preserves status change information to be used in `after_commit` callbacks.
    # Ideally, `*_change` is retrevied using `*_previous_change` in `after_commit` callbacks. However, If there are
    # multiple saves in a transaction, then *_previous_changes will only return the changes from the last save which can
    # cause changes to be missed when using an after_commit callback.
    #
    def eavesdrop_on_status_change
      @status_change = status_id_change
    end

    # END - InstanceMethods
  end
end
