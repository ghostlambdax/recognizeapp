require File.join(Rails.root, 'lib/data_reporter')

class Admin::IndexController < Admin::BaseController

  def index

    setup_data!

    @limit = params[:limit].present? ? params[:limit].to_i : 25

    @sorted_companies = @companies
    @company_auth_map = User
                          .joins(:authentications)
                          .where(authentications: {provider: "yammer"})
                          .distinct(:company_id)
                          .pluck(:company_id).inject({}){|hash, cid| hash[cid] ||= true; hash }

    @spacer = ' -- '

    sort_data!

  end

  def emails
    @emails = EmailLog.order("date desc").paginate(page: params[:page], per_page: 20)
  end
  def email
    @email = EmailLog.find(params[:id])
  end

  def signup_requests
    @requests = SignupRequest.scoped
  end

  def login
  end

  def login_as
    if params[:id].present?
      @user = User.find(params[:id])
    else
      network = params[:network] || (@company || current_user.company).domain
      @user = User.not_disabled.where(email: params[:email], network: network).first
    end

    if @user.present?
      if @user.id == current_user.acting_as_superuser
        session.delete(:superuser)
        redirect_url = admin_company_path(current_user.company)
      else
        session[:superuser] = current_user.id
        redirect_url = root_path
      end

      user_session = UserSession.new(@user, true)
      user_session.save!
      redirect_to redirect_url

    else
      flash[:error] = "There is no user with that email address"
      render "login"
    end
  end

  def analytics
    @data = Company.analytics_data
    @company_count = Company.count
    @activated_companies = @data.activated_companies
    @report = DataReporter::Report.new(Company.analytics_data)
  end

  def refresh_analytics
    Company.analytics_data.refresh!
    @data = Company.analytics_data
    redirect_to admin_analytics_path
  end

  def queue
    @jobs = Delayed::Job.where("failed_at is null").order("created_at asc")
    @jobs = @jobs.where(queue: params[:queue]) if params[:queue].present?
    @counts = Delayed::Job.where("failed_at is null").order("created_at asc").group_by(&:queue).map{|q,j|  [q, j.length]}
    @failed_jobs = Delayed::Job.where("failed_at is NOT null").order("created_at desc")
    @company = current_user.company
    @datatable = DelayedJobsDatatable.new(view_context, @company, params[:failed_queue].present?)
    respond_with(@datatable)
  end

  ALLOWABLE_QUEUE_TASKS = [:refresh_cached_yammer_groups!, :prime_caches!]
  def clear_queue_task
    task = params[:task].to_sym
    if ALLOWABLE_QUEUE_TASKS.include?(task)
      Delayed::Job.where("handler like '%method_name: :#{task}%'").delete_all
      flash[:notice] = "Removed tasks for #{task}"
    end

    redirect_to admin_queue_path

  end

  def purge_failed_queue
    @failed_jobs = Delayed::Job.where("failed_at is NOT null").limit(500).order("created_at asc")
    @failed_jobs.destroy_all
    flash[:notice] = "Successfully purged failed jobs"
    render js: "window.location='#{admin_queue_path(purge_failed_queue: true)}'"
  end

  def graph
    setup_data!
    @graph_data = {
        companies: GraphData.load(@companies, :weekly),
        recognitions: GraphData.load(@recognitions, :weekly),
        users: GraphData.load(@users, :weekly),
        approvals: GraphData.load(@recognition_approvals, :weekly),
        comments: GraphData.load(@comments, :weekly),
        company_fulfilled_redemptions: GraphData.load(@company_fulfilled_redemptions, :weekly),
        provider_redemptions: GraphData.load(@provider_redemptions, :weekly),
        provider_redemption_amounts: GraphAggregateAttributeData.load(@provider_redemption_amounts, :weekly, "sum(amount) as count")
    }
    render action: "graph", layout: false
  end

  def engagement

    @datatable = CompaniesDatatable.new(view_context)

    if request.xhr?
      respond_with @datatable
    else
      render action: "engagement"
    end

  end

  def refresh_cms_cache
    CmsManager.delay(queue: 'priority_caching').reset_page_caches
    render json: {success: true}, layout: false
  end

  private
  def setup_data!
    @recognize = Company.where(domain: "recognizeapp.com").first

    if params[:filtered_network].present?
      @companies = Company.where("companies.domain  like '%#{params[:filtered_network]}%' ")
      company_ids = @companies.map(&:id)
      @users = User.unscope(:joins).where("users.company_id IN (?)", company_ids)
      @recognitions = Recognition.where(sender_company_id: company_ids)
      recognition_ids = @recognitions.map(&:id)
      @top_badges = Badge.top_badges_for_companies(company_ids, recognition_ids: recognition_ids)
      @recognition_approvals = RecognitionApproval.joins(:recognition).where("recognition_approvals.created_at > ?", Time.parse("Feb 1, 2013")).where("recognitions.id IN (?)", recognition_ids)
      @comments = Comment.joins(:commenter).where("users.company_id IN (?)", company_ids)
      @company_fulfilled_redemptions = Redemption.joins(:reward).where("rewards.provider_reward_id IS NULL").where("redemptions.company_id IN (?)", company_ids).where("redemptions.created_at > ?", Time.parse("May 28th, 2017"))
      @provider_redemptions = Redemption.joins(:reward).where("rewards.provider_reward_id IS NOT NULL").where("redemptions.company_id IN (?)", company_ids).where("redemptions.created_at > ?", Time.parse("May 28th, 2017"))
      @provider_redemption_amounts = Rewards::FundsTxn.not_admin_acct.redemption.debit.joins(funds_account: :company).where(companies: {id: company_ids})
    else
      @companies = Company.where("companies.id <> #{@recognize.id}").order("companies.created_at desc")
      @users = User.unscope(:joins).where("company_id <> #{@recognize.id}")
      @recognitions = Recognition.where("(recognitions.sender_company_id <> #{@recognize.id}) AND badge_id NOT IN (?)", Badge.system_badge_ids)
      @top_badges = Badge.top_badges
      @recognition_approvals = RecognitionApproval.where("created_at > ?", Time.parse("Feb 1, 2013"))
      @comments = Comment.where("created_at > ?", Time.parse("Feb 1, 2013"))
      @company_fulfilled_redemptions = Redemption.joins(:reward).where("rewards.provider_reward_id IS NULL").where("redemptions.created_at > ?", Time.parse("May 28th, 2017"))
      @provider_redemptions = Redemption.joins(:reward).where("rewards.provider_reward_id IS NOT NULL").where("redemptions.created_at > ?", Time.parse("May 28th, 2017"))
      @provider_redemption_amounts = Rewards::FundsTxn.not_admin_acct.redemption.debit
    end

  end

  def sort_data!
    if params[:order_by]
      @sorted_companies = case params[:order_by]
        when "last_recognition"
          @sorted_companies.sort_by{|c| c.last_recognition_sent_at || Time.at(0)}.reverse!
        when "last_user"
          @sorted_companies.sort_by{|c| c.last_user_created_at || Time.at(0)}.reverse!
        when "most_users"
          @sorted_companies.to_a.sort!{|c1, c2| c2.users_count <=> c1.users_count}
        when "most_recognitions_sent"
          @sorted_companies.to_a.sort!{|c1, c2| c2.sent_user_recognitions_count <=> c1.sent_user_recognitions_count}
        when "most_recognitions_received"
          @sorted_companies.to_a.sort!{|c1, c2| c2.received_user_recognitions_count <=> c1.received_user_recognitions_count}
        when "yammer"
          res = @sorted_companies.to_a.sort!{|c1, c2|
            c1yammer = @company_auth_map[c1.id].present?
            c2yammer = @company_auth_map[c2.id].present?
            if (c1yammer == c2yammer)
              c2.id <=> c1.id
            elsif c1yammer and !c2yammer
              -1
            elsif !c1yammer and c2yammer
              1
            end
          }
      end
    else
      @sorted_companies = @sorted_companies.limit(@limit)
    end
  end
end
