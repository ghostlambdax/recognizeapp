module Recognize
  AVAILABLE_LOCALE_INFO = {"en" => "United States English",
                           "en-GB" => "Great Britain English",
                           "en-AU" => "Australian English",
                           "zh-TW" => "Chinese (Taiwan)",
                           "zh-CN" => "Chinese (Simplified)",
                           "ar" => '(Arabic) العربية',
                            "es" => "Español (Spanish)",
                            "cs" => 'Czech',
                           "ja" => 'Japanese',
                           "ko" => 'Korean',
                           "pl" => 'Polish',
                           "pt" => 'Portuguese',
                           "fr" => 'French',
                           "fr-CA" => 'French Canadian',
                           "de" => 'German' }.sort_by{|k,v| v.downcase}.to_h
  def self.available_locale_info
    AVAILABLE_LOCALE_INFO
  end

  def self.available_locales
    available_locale_info.keys
  end
end
