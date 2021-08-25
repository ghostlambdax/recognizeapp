# frozen_string_literal: false

# This class is meant to bundle up a view context
# keeping only what matters and also providing
# access to things like view helpers
#
# In other words, it going to provide a micro version of a view context
# by only serializing the state for:
#
#  + params (request params)
#  + current_user (currently logged in user in session)

# Non-state view behavior that will be provided:
#  + route helpers

# NOTE: this has dependencies on:
#  + ApplicationController
#  + ActionController::Parameters
#
# But hopefully it should be fairly localized and not too intrusive
# ....hopefully being the operative word
class SerializableViewPresenter
  include UsersHelper
  include NominationsHelper
  include RecognitionsHelper

  attr_reader :params

  delegate :company, to: :current_user

  def initialize(view)
    # This makes an assumption that ActionController::Params is lightweight
    # or has GlobalID support to easily be stuffed into DB table
    @params = view.params.is_a?(ActionController::Parameters) ? view.params : ActionController::Parameters.new(view.params)
    @current_user_id = view.current_user.id
  end

  def company
    @company ||= current_user.company
  end

  def current_user
    @current_user ||= User.find(@current_user_id) if @current_user_id
  end

  def self.from_h(hash)
    hash[:current_user] = Struct.new(:id).new(hash[:current_user_id] || hash["current_user_id"])
    new(Hashie::Mash.new(hash))
  end

  def to_h
    {params: params.as_json, current_user_id: current_user.id}
  end

  # the session here is a poor approximation of an actual view session
  # Its just meant to be a place to stash data that won't get serialized
  # The data that gets stashed must be able to be reconstructed from the
  # params upon initialization of the parent object (Eg DatatablesBase)
  # Ses UsersAnniversaryDatatable for an example
  def session
    @session ||= OpenStruct.new
  end

  def view
    @view ||= begin
     view = ActionView::Base.new
     view.class_eval { include ApplicationHelper }
     view.class_eval { include Rails.application.routes.url_helpers }
     view
   end
  end

  def method_missing(method, *args, &block)
    # Makes sure we have @company which is required by view helpers
    # Its likely method_missing is called by view helpers
    company
    if view.respond_to?(method)
      view.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, *)
    view.respond_to?(method) || super
  end
end
