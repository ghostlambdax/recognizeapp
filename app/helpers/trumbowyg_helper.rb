module TrumbowygHelper
  private

  def set_gon_attrs_for_trumbowyg
    company = @recognition&.authoritative_company || @company
    gon.push(
      recognition_wysiwyg_editor_enabled: company.recognition_wysiwyg_editor_enabled?,
      recognition_editor_settings: company.settings.recognition_editor_settings,
      recognition_image_upload_path: upload_image_recognitions_path(network: company.domain),
      giphy_api_key: get_giphy_api_key_with_fallback,

      url_error_messages: {
        is_invalid: I18n.t('activerecord.errors.models.recognition.url_is_invalid'),
        must_start_with_http: I18n.t('activerecord.errors.models.recognition.url_must_start_with_http'),
      }
    )
  end

  # public key fallback - this is subject to rate limit constraints & not recommended for production env
  # https://giphy.api-docs.io/1.0/welcome/access-and-api-keys#public-beta-key
  def get_giphy_api_key_with_fallback
    public_beta_key = 'dc6zaTOxFJmzC'
    gon.giphy_api_key = Recognize::Application.config.rCreds.dig('giphy', 'api_key') || public_beta_key
  end
end
