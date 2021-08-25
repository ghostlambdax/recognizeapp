# frozen_string_literal: true

class Cms::BaseController < ApplicationController
  include CmsConcern
  layout 'cms'

  private
  def is_home?
    true
  end

end
