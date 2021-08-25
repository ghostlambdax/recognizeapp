module EnumHelper

  def options_for_enum(object, enum)
    options = enums_to_translated_options_array(object.class.name, enum.to_s)
    options_for_select(options, object.send(enum))
  end

 # Example localization
 # en:
 #   activerecord:
 #     enums:
 #      wine:
 #        color:
 #          red:   "Red Wine"
 #          white:  "White Wine"
  def enums_to_translated_options_array(klass, enum)
    klass.classify.safe_constantize.send(enum.pluralize).map {
        |key, value| 
          [I18n.t("activerecord.enums.#{klass.underscore}.#{enum}.#{key}", default: key.humanize), key]
    }
  end

end