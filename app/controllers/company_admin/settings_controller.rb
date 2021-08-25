module CompanyAdmin
  class SettingsController < CompanyAdmin::BaseController


    def index
      @user = current_user
      @saml_configuration = @company.saml_configuration || @company.build_saml_configuration
      @badges_with_forced_privacy_present = @company.badges.with_forced_privacy.exists?
    end

    def update
      @company.settings.update(company_params)
      respond_with @company
    end

    def fb_workplace_groups
      if @company.settings.fb_workplace_community_id.blank? && @company.settings.fb_workplace_token.blank?
        @groups = [{name: "Click Install Integration above to select a group"}]
      elsif @company.settings.fb_workplace_community_id.blank?
        @groups = [{name: "Click Install Integration above to select a group"}]
      elsif @company.settings.fb_workplace_token.blank?
        @groups = [{name: "Click Install Integration above to select a group"}]
      elsif current_user.fb_workplace_id.blank?
        @groups = [{name: "To configure groups, type 'Connect' into the Recognize Chat bot."}]
      else
        @groups = @company.fb_workplace_groups(current_user)
        if !@groups.kind_of?(Array)
          @groups = [{name: "Could not load groups, try reinstalling integration"}]
        elsif @company.settings.fb_workplace_post_to_group_id.present? && !@groups.map(&:id).include?(@company.settings.fb_workplace_post_to_group_id)
          @groups = [{name: "A group has been set but you do not have permission to view the group"}]
        end
      end
      
      render json: @groups, root: false
    end





    private
    def company_params
      params.require(:company_setting).permit(*CompanySetting::VALID_SETTINGS, profile_badge_ids: [])
    end
  end
end
