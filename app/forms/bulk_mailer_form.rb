class BulkMailerForm
  include ActiveModel::Model
  include LinksHelper

  include Rails.application.routes.url_helpers

  GROUPS = [:everyone, :pending, :by_role, :by_status, :by_team]
  DEFAULT_GROUP = :everyone
  INVITE_LINK_TEMPLATE = "%{password_link}%"
  SSO_LINK_TEMPLATE = "%{sso_link}%"
  USER_TEMPLATE = "%{user}%"

  attr_accessor :company, :sender, :group, :subject, :body, :sms_body, :roles, :statuses, :teams

  # FIXME: not sure why this doesnt work
  # validates :company, sender, :group, :mailer_class, :template, presence: true

  validates :subject, :body, presence: true
  validate :must_choose_group
  validate :must_have_company_and_sender
  validate :must_have_one_status, if: ->{ group.to_sym == :by_status }
  validate :must_have_one_team, if: ->{ group.to_sym == :by_team }

  def attributes
    {
      group: @group,
      subject: @subject,
      body: @body,
      sms_body: @sms_body,
      roles: @roles,
      statuses: @statuses,
      teams: @teams
    }
  end

  def body
    @body || default_body
  end

  def sms_body
    @sms_body || default_sms_body
  end

  def group
    @group || default_group
  end

  def persisted?
    valid?
  end

  def signature # for delayed job dupe prevention
    "bulk-mail-#{@company.id}-#{@sender.id}-#{group}"
  end

  def subject
    @subject || default_subject
  end

  def send!
    if valid?
      delay(queue: 'bulkemail').do_send
    end
  end

  def self.i18n_scope
    :activerecord
  end

  private
  def default_body
    "Hi #{USER_TEMPLATE},&#13;&#10;&#13;&#10;Welcome to Recognize. To get started click here: #{INVITE_LINK_TEMPLATE}".html_safe
  end

  def default_sms_body
     "Welcome to Recognize! To get started click here: #{INVITE_LINK_TEMPLATE}".html_safe
  end

  def default_group
    DEFAULT_GROUP
  end

  def default_subject
    "Get started with Recognize"
  end

  def must_have_company_and_sender
    errors.add(:base, "A company is not specified") unless company.present?
    errors.add(:base, "A sender is not specified") unless sender.present?
  end

  def must_have_one_status
    errors.add(:base, "At least one status must be specified") if statuses.blank?
  end

  def must_have_one_team
    errors.add(:base, "At least one team must be specified") if teams.blank?
  end

  def must_choose_group
    errors.add(:base, "A set of users must be chosen") if group.blank?
  end

  def do_send
    sendable_users.each do |user|
      do_send_to_user(user)
    end
  end

  def do_send_to_user(user)
    unless attributes[:body].blank? || user.email.blank?
      UserNotifier.delay(queue: 'priority')
                  .from_template(sender, user, subject, formatted_email_body(user))
      user.set_status!(:invited) if user.pending_invite? && attributes[:body].include?("%{password_link}%")
    end

    unless attributes[:sms_body].blank? || user.phone.blank?
      SmsNotifierJob.perform_now(user.id, formatted_sms_body(user))
      user.set_status!(:invited) if user.pending_invite? && attributes[:sms_body].include?("%{password_link}%")
    end
  end

  def formatted_sms_body(user)
    formatted_body(user, sms_body, use_html: false )
  end

  def formatted_email_body(user)
    formatted_body(user, body)
  end

  def formatted_body(user, old_body, use_html: true)
    new_body = old_body.gsub(USER_TEMPLATE, "#{user.first_name}")

    if new_body.match(INVITE_LINK_TEMPLATE)
      link = invite_or_password_reset_link(user)
      new_body = substitute_template_with_link(new_body, INVITE_LINK_TEMPLATE, link, use_html: use_html)
    end

    if new_body.match(SSO_LINK_TEMPLATE)
      link = sso_saml_index_url(network: user.company.domain, host: Recognize::Application.config.host)
      new_body = substitute_template_with_link(new_body, SSO_LINK_TEMPLATE, link, use_html: use_html)
    end

    new_body.gsub(/\n/, '<br/>') if use_html
    return new_body
  end

  def substitute_template_with_link(body, template, link, use_html: true)
    link = !use_html ? link : "<a href='#{link}'>#{link}</a>"
    body.gsub(template, link)
  end

  def sendable_users
    case group.to_sym
    when :everyone
      company.users.not_disabled
    when :pending
      company.users.where(status: User::PENDING_STATES)
    when :by_role
      if roles.blank?
        company.get_users_with_no_company_roles
      else
        user_ids = roles.inject([]){|set, role_id| set += company.get_user_ids_by_company_role_id(role_id)}
        User.not_disabled.where(id: user_ids)
      end
    when :by_status
      company.users.select{|u| statuses.include?(u.status) }
    when :by_team
      User.not_disabled.joins(:user_teams).where(company_id: company.id, user_teams: {team_id: teams})
    end
  end
end
