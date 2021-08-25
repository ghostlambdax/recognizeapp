require 'will_paginate/array'
class Api::V2::Endpoints::Users::Import < Api::V2::Endpoints::Users
  resource :users, desc: '' do
    # TODO: allow companies to import to their own network
    # ...

    # POST /users/import_with_network
    # Trusted api clients ONLY (slack, sftp)
    # allows specifying which company to import to
    desc 'Import a spreadsheet via a remote file | Requires TRUSTED oauth scope' do
      detail 'Give a url to a remotely accessible file that is a spreadsheet to import'
    end

    params do
      requires :s3_path, type: String
    end

    oauth2 'trusted'
    route_setting(:x_auth_email, required: false)

    # Thoughts:
    # I was flipping back and forth between having the parameter be
    # an s3_path or a generic absolute url
    # A url allows generic testing without being beholden to s3
    # However, an s3 path is safer in case the api endpoint is compromised, somehow
    # as the attacker would also need access to s3 (unlikely) to modify user accounts
    # en masse
    # This also makes this less applicable to any third parties using the api
    # but I suppose I can always add an option url parameter if we need to work with that
    # Or possible make the bucket selectable and whitelistable based on token
    #
    # For now, for the s3 -> lambda feature
    # the s3_path parameter should be the relative path to the uploads directory within the companies
    # configured account/domain
    # Ie, basset.org/uploads/spreadsheet.xlsx
    post '/import_with_network' do
      # this assumes url is s3 relative path in sftp bucket

      # NOTE: I've chosen to do the exception handling for remote import at the api level since this is
      #       really the only superset that is called.
      #       However, an argument can be made for also adding exception handling in the RemoteImportService
      #       class, but I think that is overkill at the moment and can always be added in later.
      #       This covers the current issue which only calls RemoteImportService through this api call.
      begin
        region = Recognize::Application.config.rCreds['aws']['region']
        sftp_bucket = Recognize::Application.config.rCreds['aws']['sftp_bucket']
        url = "https://s3-us-west-2.amazonaws.com/#{sftp_bucket}/#{params["s3_path"].to_s}"
        company = resource_owner
        remote_import_service = AccountsSpreadsheetImport::RemoteImportService.new(company.id, url)

        if remote_import_service.valid_to_process?
          # reinstantiate so DJ does not over-serialize
          AccountsSpreadsheetImport::RemoteImportService.delay(queue: 'remote_import', attempts: 1).import(company.id, url)
          present(true, {type: "Message", ok: "success", message: "Import scheduled. A report will be sent when the import has completed."})
        else
          remote_import_service.send_error_report!
          raise ActiveRecord::RecordInvalid, remote_import_service.importer
        end
      rescue StandardError => e
        ::Recognizebot.say(text: "<!subteam^SQECBCGAW> sFTP Import failed for Company(#{company.domain}) - #{e.message}", channel: "#system-notifications")
        Rails.logger.debug "Caught exception importing file: #{url}"
        Rails.logger.debug "Company: #{company.domain}"
        Rails.logger.debug "Exception: #{e.message}"

        raise e
      end
    end
  end
end
