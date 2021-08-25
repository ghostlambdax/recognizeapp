# frozen_string_literal: true

class DelayedJobsDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :created, orderable: true, sort_column: "delayed_jobs.created_at"},
    {attribute: :queue, orderable: true, sort_column: "delayed_jobs.queue"},
    {attribute: :object_label, orderable: false, title: "Object"},
    {attribute: :method_name, orderable: false, title: "Method"},
    {attribute: :arguments, orderable: false, title: "Arguments"}
  ].freeze

  def serializer
    DelayedJobsSerializer
  end

  def initialize(view, company, is_failed_queue)
    @is_failed_queue = is_failed_queue
    super(view, company)
  end

  # Note: This is used for export filename only
  # for all other purposes, specific namespace for active/failed table has been passed from the view
  def namespace
    'delayed_jobs'
  end

  def colvis_options
    {}
  end

  def default_order
    "[[ 0, \"asc\" ]]"
  end

  private

  def all_records
    if @is_failed_queue
      Delayed::Job.where.not(failed_at: nil)
    else
      Delayed::Job.where(failed_at: nil)
    end
  end

  def filtered_records
    jobs = all_records_filtered_by_date_range(table: :delayed_jobs)
    search_term = params.dig(:search, :value)
    if search_term.present?
      jobs = jobs.where("delayed_jobs.queue like :search", search: "%#{search_term}%")
    end
    jobs = jobs.order(sort_columns_and_directions)
    jobs = jobs.paginate(page: page, per_page: per_page)
    jobs
  end

  class DelayedJobsSerializer < BaseDatatableSerializer

    attributes :id, :timestamp, :created, :queue, :object_label, :DT_RowId, :method_name, :arguments

    def timestamp
      job.created_at.to_f.to_s
    end

    def created
      localize_datetime(job.created_at, :friendly_with_time_seconds)
    end

    def queue
      dj_queue(job)
    end

    def object_label
      dj_object_label(job)
    end

    def method_name
      dj_method_name(job)
    end

    def arguments
      dj_args(job)
    end

    def current_user
      context.current_user
    end

    def DT_RowId
      prefix = params[:failed_queue].present? ? "failed" : "active"
      "#{prefix}_delayed_jobs_row_#{job.id}"
    end

    def job
      @object
    end

  end
end
