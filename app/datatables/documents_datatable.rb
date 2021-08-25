# frozen_string_literal: true

require 'will_paginate/array'
class DocumentsDatatable < DatatablesBase
  COLUMN_ATTRIBUTES = {
    2 => {orderable: false},
    4 => {orderable: false},
    6 => {orderable: false, export_format: :nodeText}
  }.freeze

  COLUMN_TABLE_MAP = {
    "filename" => "attachments.original_filename",
    "description" => "attachments.description",
    "requester" => "attachments.requester",
    "request_date" => "attachments.requested_at",
    "uploader" => "attachments.uploader",
    "upload_date" => "attachments.created_at",
    "actions" => ""
  }.freeze

  # Order by descending `upload_date` by default.
  def default_order
    @default_order ||= begin
      col = column_table_map.keys.index("upload_date")
      "[[ #{col}, \"desc\" ]]"
    end
  end

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def columns
    arr = column_table_map.keys
    arr.size.times.zip(arr).to_h
  end

  def column_exclusions
    params[:type] == 'uploads' ? ['requester', 'request_date'] : ['uploader']
  end

  def namespace
    "documents"
  end

  def serializer
    DocumentSerializer
  end

  def all_records
    documents = company.documents.not_invoice.includes(:requester, :uploader)
    documents = params[:type] == "uploads" ? documents.uploads : documents.downloads
    documents = documents.order(sort_columns_and_directions) if params[:order].present?
    documents
  end

  def filtered_records
    set = all_records_filtered_by_date_range(table: :attachments)
    search_term = params.dig(:search, :value)
    if search_term.present?
      columns_to_search_in = %w[original_filename description]
      set = filtered_set(set, search_term, columns_to_search_in)
    end
    paginated_set(set)
  end

  class DocumentSerializer < BaseDatatableSerializer
    attributes :filename, :description, :uploader, :requester, :actions, :upload_date, :request_date, :DT_RowId

    def uploader
      document.uploader.full_name if document.uploader.present?
    end

    def requester
      return unless document.requester.present?

      if document.requester == User.system_user && context.params[:type] == "downloads"
        document.company.name
      else
        document.requester.full_name
      end
    end

    def request_date
      context.localize_datetime(document.requested_at, :friendly_with_time)
    end

    def upload_date
      context.localize_datetime(document.uploaded_at, :friendly_with_time)
    end

    def actions
      download_link + delete_link
    end

    def DT_RowId
      "document-#{document.id}"
    end

    def document
      @object
    end

    def delete_link
      context.link_to(
        I18n.t("dict.delete"),
        document_destroy_endpoint(document),
        method: :delete,
        remote: true,
        data: { confirm: I18n.t("forms.are_you_sure") },
        class: "button button-full-width"
      )
    end

    def download_link
      context.link_to(
        I18n.t("dict.download"),
        document_show_endpoint(document),
        target: "_blank",
        class: "button button-full-width button-primary",
        rel: "noopener noreferrer"
      )
    end
  end
end
