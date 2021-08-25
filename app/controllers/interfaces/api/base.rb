require 'rack/cors'
module Api
  class Dispatch < Grape::API
    mount Api::V2::Base

    format :json
    route :any, '*path' do
      status 404
      {error: "Path not found", type: "Error", code: "404", ok: "error"}
    end
  end

  Base = Rack::Builder.new do
    use Api::Logger
    run Api::Dispatch
  end
end
