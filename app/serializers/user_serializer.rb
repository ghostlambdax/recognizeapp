class UserSerializer < ActiveModel::Serializer
  include DateTimeHelper

  attributes :id, :email, :full_name, :first_name, :last_name, :full_name_link, :slug, :url, :status, :created_at
  # attributes :id, :email, :full_name, :first_name, :last_name, :full_name_link, :job_title, :manager, :roles, :teams, :slug, :url, :status, :created_at

  def created_at
    localize_datetime(user.created_at, :friendly_with_time)
  end

  def full_name_link
    ActionController::Base.helpers.link_to(user.full_name, url, target: "_blank")
  end

  def manager
    user&.manager&.email
  end

  def roles
    user.roles.map(&:name).join(", ")
  end

  def slug
    user.slug
  end

  def teams
    user.teams.map(&:name).join(", ")
  end

  def url
    Rails.application.routes.url_helpers.user_url(user, network: user.network, host: Recognize::Application.config.host)
  end

  def user
    @object
  end

  def timestamp
    user.created_at.to_f
  end

end
