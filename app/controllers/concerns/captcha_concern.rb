module CaptchaConcern
  extend ActiveSupport::Concern

  included do
    # Enable captcha from controller level with `enable_captcha` class function.
    # Format:
    #   - enable_captcha only: [:action_name, :action_name]
    #   - enable_captcha only: [:action_name, :action_name], if: Proc.new {|controller| true }
    #   where array `only` option is required and if` option is optional.
    # eg:
    #   enable_captcha only: [:show], if: Proc.new { |c| c.params[:invite].present? }
    before_action :set_gon_skip_captcha
  end

  module ClassMethods
    def enable_captcha(only: [], **args)
      captcha_enabled_config.actions = only
      captcha_enabled_config.condition = args[:if]
    end

    def captcha_enabled_config
      @captcha_enabled_config ||= CaptchaEnabledConfiguration.new
    end
  end

  protected

  def verify_recaptcha(opts = {})
    skip_captcha? || super(model: opts[:model])
  end

  private

  def set_gon_skip_captcha
    gon.skip_captcha = skip_captcha?
  end

  def skip_captcha?
    Recaptcha.skip_env?(Rails.env) ||
      [:site_key, :secret_key].any? { |k| Recaptcha.configuration.send(k) }.blank? ||
      captcha_not_enabled? || skip_captcha_for_ghost_inspector?
  end

  def captcha_not_enabled?
    return true if captcha_enabled_config.empty? || captcha_enabled_config.condition_failed?

    !captcha_enabled_config.enabled_for?(self.action_name)
  end

  def skip_captcha_for_ghost_inspector?
    skip = IpChecker::GhostInspector.valid_ip?(request.ip)
    Rails.logger.debug "ApplicationController#skip_captcha? - is #{skip} from IpChecker::GhostInspector.valid_ip? - #{request.ip}"
    skip
  end

  def captcha_enabled_config
    config = self.class.captcha_enabled_config
    config.controller = self
    config
  end

  class CaptchaEnabledConfiguration
    attr_accessor :actions, :condition, :controller

    def initialize
      @actions = []
      @condition = nil
      @controller = nil
    end

    def empty?
      actions.empty?
    end

    def enabled_for?(action = '')
      actions.include?(action.to_sym)
    end

    def condition_failed?
      return false if condition.nil? || !condition.is_a?(Proc)

      !condition.call(controller)
    end
  end
end
