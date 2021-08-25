class HelpController < ApplicationController

  def index
    if current_user.present? && current_user.company.customizations.present? && current_user.company.customizations.youtube_id.present?
      @youtube_id = current_user.company.customizations.youtube_id
    else
      @youtube_id = "l9k_CSBHPNY"
    end
  end
end