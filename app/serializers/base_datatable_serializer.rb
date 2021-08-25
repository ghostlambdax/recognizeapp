#
# Note: Inheriting from this class will enforce auto-escaping of all attribute values by default
#
class BaseDatatableSerializer < ActiveModel::Serializer
  include ERB::Util # for html_escape()
  attr_accessor :disable_attribute_escaping

  # This is necessary to pass context params through to
  # UrlHelperCallWithDefault
  def url_options
    static_params = ApplicationController::PERSISTENT_PARAMS.without(:locale)
    context.params.permit(static_params).to_h.symbolize_keys.tap do |opts|
      opts[:locale] = I18n.locale unless I18n.locale == I18n.default_locale
    end
  end

  private

  def method_missing(method, *args, &block)
    if context.respond_to?(method)
      context.send(method, *args, &block)
    else
      super
    end
  end

  # wraps parent method to globally escape HTML in attribute values for frontend injection
  def attributes
    return super if disable_attribute_escaping
    escaped_attr_values = super.map do |attr, val|
      val = html_escape(val) if val.present? && html_safe_attributes.exclude?(attr)
      [attr, val]
    end

    Hash[ escaped_attr_values ]
  end

  # intended to be used by child classes to prevent attributes with safe application html from being escaped
  def html_safe_attributes
    []
  end
end
