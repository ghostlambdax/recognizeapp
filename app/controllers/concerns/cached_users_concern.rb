module CachedUsersConcern
  private

  def refresh_cached_users!
    company = @company || @user.company
    return false unless company
    company.refresh_cached_users!
  end
end
