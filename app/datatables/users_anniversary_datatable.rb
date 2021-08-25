# frozen_string_literal: true

class UsersAnniversaryDatatable < UsersDatatable

  COLUMN_SPEC = [
    {attribute: :first_column, orderable: false, colvis: :hide, sort_column: proc { company.uses_employee_id? ? "users.employee_id" : "users.id" }},
    {attribute: :email, orderable: true, colvis: :hide, sort_column: "users.email"},
    {attribute: :first_name, orderable: true, colvis: :hide, sort_column: "users.first_name"},
    {attribute: :last_name, orderable: true, colvis: :hide, sort_column: "users.last_name"},
    {attribute: :full_name, orderable: false},
    {attribute: :user_status, orderable: false, colvis: :hide, title: proc { I18n.t('dict.user_status') }},
    {attribute: :manager, orderable: false, colvis: :hide},
    {attribute: :teams, orderable: false, title: proc { I18n.t("company_admin.accounts.company_teams") }, colvis: :hide},
    {attribute: :roles, orderable: false, title: proc { I18n.t("company_admin.accounts.company_roles") }, colvis: :hide},
    {attribute: :department, orderable: true, title: proc { I18n.t("dict.department") }, colvis: :hide, sort_column: "users.department"},
    {attribute: :country, orderable: true, title: proc { I18n.t("dict.country") }, colvis: :hide, sort_column: "users.country"},
    {attribute: :next_event_label, orderable: false, title: proc { I18n.t('anniversary.next_event') }},
    {attribute: :privacy_preference, orderable: false, title: proc { I18n.t('anniversary.privacy_enabled') }},
    {attribute: :date, orderable: true, title: proc { I18n.t("dict.date") }, sort_column: "DAYOFYEAR(date)"},
    {attribute: :year, orderable: true, title: proc { I18n.t("dict.start_year") }, sort_column: "YEAR(date)"},
    {attribute: :anniversary_status, orderable: false, title: proc { I18n.t("anniversary.event_status") }},
    {attribute: :points, orderable: false, title: proc { I18n.t("dict.points") }}
  ].freeze

  def initialize(view, company)
    # metaprogramming, huzzah!
    # putting these methods just on the object instance
    # The view passed in here can be either SerializableViewPresenter (SVP)
    # or a proper Controller view context which has a proper session. 
    # SVP has a fake session, using OpenStruct
    # And due to the way that i'm forcibly adding these methods just on the object
    # instance, it doesn't really matter what type session is. 

    # The idea is that we need to stash these objects `somewhere` but make
    # sure they aren't serialized so they don't crash when trying to get stuffed 
    # into a database column. 

    # The purpose of stashing these objects is for performance since these
    # classes do a lot of querying of objects, so we make sure we only do it once
    # per datatable.
    view.session.singleton_class.instance_eval do
      attr_accessor :recognizer, :anniversary_badges
    end
    view.session.recognizer = Anniversary::Recognizer.new(company)
    view.session.anniversary_badges = AnniversaryBadgeManager.company_anniversary_badges(company)
    super
  end

  def all_records
    base_query = User.not_disabled.where(company_id: company.id)
    sql1 = base_query.select(selects(:start_date)).where("users.start_date IS NOT NULL OR users.start_date <> ''")
    sql2 = base_query.select(selects(:birthday)).where("users.birthday IS NOT NULL OR users.birthday <> ''")
    union = sql1.union_all(sql2)
    union.order(sort_columns_and_directions)
  end

  def filtered_records
    ar_connection = ActiveRecord::Base.connection    
    where_clauses = []

    records = self.all_records
    if params[:month]
      month_index = I18n.t('date.month_names').index(params[:month])
      records = records.where("MONTH(date) = ?", month_index) if month_index.present?
    end

    if params[:search].present? && params[:search][:value].present?
      search_tokens = params[:search][:value].split(" ").map(&:strip).join(" ")

      search = ar_connection.quote("%#{search_tokens}%")
      columns_to_search_in = [
        "users.first_name",
        "users.last_name",
        "users.email",
        "users.department",
        "users.country"
      ]
      where_clauses << columns_to_search_in.map { |r| " #{r} like #{search} " }.join("or")
    end

    records = records.where(where_clauses.join(" AND ")) if where_clauses.present?
    records.paginate(page: page, per_page: per_page)
  end

  def filters
    # selected = Time.current.month
    selected = 0
    months = I18n.t('date.month_names').map { |m| [m.presence || "All", m] }
    [SelectFilter.new(:month, I18n.t('interval.month'), months, selected: selected)]
  end

  def namespace
    "anniversaries"
  end

  def default_order
    date_index = COLUMN_SPEC.index { |c| c[:attribute] == :date }
    first_name_index = COLUMN_SPEC.index { |c| c[:attribute] == :first_name }
    last_name_index = COLUMN_SPEC.index { |c| c[:attribute] == :last_name }
    "[[ #{date_index}, \"asc\" ],[#{first_name_index}, \"asc\"],[#{last_name_index}, \"asc\"]]"
  end

  def recognizer
    view.session.recognizer
  end

  def selects(date_attribute)
    date_select = if date_attribute == :birthday
      "birthday AS date, 'birthday' as event_type"
    elsif date_attribute == :start_date
      "start_date AS date, 'start_date' as event_type"
    else
      raise "Not supported date attribute: #{date_attribute}"
    end
    "*, #{date_select}"
  end

  def serializer
    AnniversaryUserSerializer
  end

  class AnniversaryUserSerializer < ActiveModel::Serializer
    attributes :id, :employee_id, :first_name, :last_name, :full_name, :email, :manager,
               :teams, :roles, :department, :country, :event_type, :next_event_label, :date,
               :year, :user_status, :anniversary_status, :privacy_preference, :points

    delegate :company, :full_name, to: :user
    delegate :service_anniversary_badges, to: :recognizer
    delegate :points, to: :next_event

    def anniversary_badges
      context.session.anniversary_badges
    end

    def anniversary_status
      next_event.enabled? ? I18n.t('dict.active') : I18n.t('dict.disabled')
    end

    def attributes(*args)
      hash = super
      user.company.custom_field_mappings.each do |cfm|
        hash[cfm.key] = user.send(cfm.key)
      end
      hash
    end

    def date
      user.date&.strftime("%m-%d")
    end

    def next_event
      NextEvent.factory(user, recognizer, anniversary_badges)
    end

    def next_event_label
      next_event.label
    end

    def manager
      user.manager&.email
    end

    def privacy_preference
      I18n.t("dict.#{next_event.privacy_preference}")
    end

    def recognizer
      context.session.recognizer
    end

    def roles
      user.company_roles.map(&:name).join(", ")
    end

    def teams
      user.teams.map(&:name).join(", ")
    end

    def user
      @object
    end

    def user_status
      context.status(user)     
    end

    def year
      case event_type
      when 'birthday'
        nil
      when 'start_date'
        user.date.year
      else
        raise "Unsupported event type"
      end
    end
  end

  class NextEvent
    attr_reader :user, :recognizer, :badges

    def self.factory(user, recognizer, badge)
      case user.event_type
      when 'birthday'
        NextBirthdayEvent.new(user, recognizer, badge)
      when 'start_date'
        NextAnniversaryEvent.new(user, recognizer, badge)
      else
        raise "Unsupported event type: #{user.event_type}"
      end
    end

    # expects user to have event_type and
    # consolidated `date` attribute
    def initialize(user, recognizer, badges)
      @user = user
      @recognizer = recognizer
      @badges = badges
    end

    def enabled?
      badge&.persisted? && !badge.disabled?
    end

    def label
      badge&.name
    end

    def points
      badge&.points
    end
  end

  class NextBirthdayEvent < NextEvent
    def badge
      recognizer.birthday_badge
    end

    def label
      I18n.t('dict.birthday')
    end

    def privacy_preference
      user.receive_birthday_recognitions_privately
    end

    def year
      nil
    end
  end

  class NextAnniversaryEvent < NextEvent
    def badge
      recognizer.detect_upcoming_service_anniversary_badge(badges, user.start_date)
    end

    def privacy_preference
      user.receive_anniversary_recognitions_privately
    end

    def year
      user.date.year
    end
  end
end
