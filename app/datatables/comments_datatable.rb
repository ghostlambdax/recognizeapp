# frozen_string_literal: true

class CommentsDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :date, orderable: true, sort_column: "comments.created_at"},
    {attribute: :full_name, orderable: false, export_format: :removeLink},
    {attribute: :email, orderable: true, sort_column: "users.email"},
    {attribute: :content, orderable: false},
    {attribute: :recognition, orderable: false, title: proc { I18n.t("dict.recognition") }, export_format: :removeLinkKeepHref},
    {attribute: :toggle_hidden_link, orderable: false, title: proc { I18n.t("dict.hide") }, export: false}
  ].freeze

  def namespace
    "comments"
  end

  def serializer
    CommentSerializer
  end

  def server_side_export
    true
  end

  private

  def all_records
    Comment
      .joins(:recognition, :commenter)
      .includes(:recognition, :commenter)
      .where(users: {company_id: company.id})
  end

  def filtered_records
    comments = all_records_filtered_by_date_range(table: :comments)

    if search_query.present?
      comments = comments.where("comments.content like :search or users.first_name like :search or users.last_name like :search or users.email like :search or recognitions.slug like :search", search: "%#{params[:search][:value]}%")
    end

    comments = comments.order(sort_columns_and_directions)
    # switched to the #paginate syntax over `page(page).per_page(per_page)` because
    # that syntax doesn't work for arrays which are necessary for testing (mocks)
    comments = comments.paginate(page: page, per_page: per_page)

    comments
  end

  class CommentSerializer < BaseDatatableSerializer
    attributes :id, :date, :email, :recognition, :commenter, :content, :DT_RowId, :timestamp, :toggle_hidden_link,
               :full_name

    def timestamp
      comment.created_at.to_f.to_s
    end

    def date
      l(comment.created_at, format: :friendly_with_time)
    end

    def current_user
      context.current_user
    end

    def DT_RowId
      "comment_row_#{comment.id}"
    end

    def email
      comment.commenter.email
    end

    def comment
      @object
    end

    def commenter
      UserSerializer.new(comment.commenter).as_json(root: false)
    end

    def full_name
      comment.commenter.full_name
    end

    def recognition
      link_to(comment.recognition.slug, recognition_url(comment.recognition, host: Recognize::Application.config.host), class: "recognition")
    end

    def toggle_hidden_link
      if comment.is_hidden?
        url = unhide_recognition_comment_path(comment.recognition, comment, comment_id_prefix: "comment_row_")
        label = "Unhide"
        klass = "unhideLink"
      else
        url = hide_recognition_comment_path(comment.recognition, comment, comment_id_prefix: "comment_row_")
        label = "Hide"
        klass = "hideLink"
      end
      link_to label, url, remote: true, method: :put, class: klass
    end
  end
end
