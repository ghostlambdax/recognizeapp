# frozen_string_literal: true

class CompanyAdmin::Anniversaries::NotificationsController < CompanyAdmin::Anniversaries::BaseController
  include SharedParamsConcern

  def show
    @roles = [Role.company_admin, Role.manager]
    @company_roles = @company.company_roles
    @teams = @company.teams   
  end

  def change_roles
    [:anniversary, :birthday].each do |event_type|
      roles = params[event_type] && params[event_type][:roles] || {}
      company_roles = params[event_type] && params[event_type][:company_roles] || {}
      teams = params[event_type] && params[event_type][:teams] || {}
      roles, company_roles, teams = permit_role_params(roles, company_roles, teams)

      assign_roles(event_type, roles)
      assign_company_roles(event_type, company_roles)
      assign_teams(event_type, teams)
    end

    head :ok
  end

 private

  def assign_roles(event_type, roles)
    temp_hash = @company.send("#{event_type}_notifieds")
    temp_hash[:role_ids] = roles.map{|role_id, _on_off| role_id.to_i}
    @company.send("#{event_type}_notifieds=", temp_hash)
    @company.save
  end

  def assign_company_roles(event_type, company_roles)
    temp_hash = @company.send("#{event_type}_notifieds")
    temp_hash[:company_role_ids] = company_roles.map{|role_id, _on_off| role_id.to_i}
    @company.send("#{event_type}_notifieds=", temp_hash)
    @company.save
  end

  def assign_teams(event_type, teams)
    temp_hash = @company.send("#{event_type}_notifieds")
    temp_hash[:team_ids] = teams.map{|team_id, _on_off| team_id.to_i}
    @company.send("#{event_type}_notifieds=", temp_hash)
    @company.save
  end

  def permit_role_params(*params)
    params.map do |param|
      unless param.is_a? Hash
        param.permit! if param.keys.all?{ |k| k =~ /\A\d+\Z/ } # numeric validation (only the keys are used)
        param = param.to_h
      end
      param
    end
  end

end
