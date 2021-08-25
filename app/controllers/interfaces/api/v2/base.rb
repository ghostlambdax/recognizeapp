require 'grape-swagger'
require 'api/v2/helpers/header_helpers'
require 'api/v2/helpers/tracking'
module Api
  module V2
    class Base < Grape::API::Instance
      extend Api::V2::Documentation
      extend Api::V2::XAuthEmail
      extend Api::V2::Authorization

      after do
        track_request
      end

      mount Api::V2::Endpoints::Auth
      mount Api::V2::Endpoints::Recognitions
      mount Api::V2::Endpoints::Users
      mount Api::V2::Endpoints::Badges
      mount Api::V2::Endpoints::Redemptions
      mount Api::V2::Endpoints::Catalogs
      mount Api::V2::Endpoints::Rewards
      mount Api::V2::Endpoints::Comments
      mount Api::V2::Endpoints::Approvals
      mount Api::V2::Endpoints::DeviceTokens
      mount Api::V2::Endpoints::Teams
      mount Api::V2::Endpoints::System

      before do
        token = headers["Authorization"].match(/^Bearer\s(.*)/)[1] rescue nil
        if token.present? && access_token = Doorkeeper::AccessToken.find_by_token(token)
          if access_token.resource_owner_id.blank?
            ensure_auth_headers_on_swagger_route(:email, :network)
          elsif access_token.scopes.include?("company")
            ensure_auth_headers_on_swagger_route(:email)
          end
        end
      end

      # #TODO: Possibly overriden after block!
      after do
        ensure_no_email_auth_headers_on_swagger_route
      end

      # markdown_adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new(render_options: { highlighter: :rouge }, fenced_code_blocks: true)
      add_swagger_documentation add_version: true,
                                    info: {title: "Recognize API", description: core_description},
                                    base_path: "/api",
                                    hide_format: true,
                                    mount_path: 'spec',
                                    hide_module_from_path: true,
                                    hide_documentation_path: true,
                                    format: :json,
                                    # markdown: markdown_adapter,#GrapeSwagger::Markdown::KramdownAdapter,
                                    # authorizations: {
                                    #   "Authorization" => {
                                    #     type: "oauth2"
                                    #   }
                                    # }
                                    authorizations: {
                                      :oauth2 => {
                                        type: "oauth2",
                                        # grantTypes: {
                                        #   "implicit" => {
                                        #     loginEndpoint: {url: ""},
                                        #     token_name: "access_token"
                                        #   },
                                        #   "authorization_code" => {
                                        #     "tokenRequestEndpoint" => {url: 'tre.url'},
                                        #     "tokenEndpoint" => {url: "te.url"}
                                        #   }
                                        # },
                                        scopes: [{"scope" => "profile"}]
                                      }
                                    }

    end
  end
end
