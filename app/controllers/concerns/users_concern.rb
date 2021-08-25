module UsersConcern
  def scoped_company
    @scoped_company ||= Company.where(domain: params[:network]).includes(:users).first
  end
  
  def scoped_user
    return @user if @user

    if params[:id]
      @user = (id_is_int?(params[:id]) ? User.find(params[:id]) : User.where(slug: params[:id], company_id: scoped_company.id).first)
      raise ActiveRecord::RecordNotFound unless @user
    else
      @user = current_user
    end
    return @user
  end  

end