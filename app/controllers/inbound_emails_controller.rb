class InboundEmailsController < ApplicationController
  def create
    @inbound_emails = mandrill_events.map{|event_hash| InboundEmail.create!(data: event_hash) }
    head :ok
  end

  private
  def mandrill_events
    JSON.parse(params[:mandrill_events])
  end
end