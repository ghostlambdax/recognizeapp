module ThirdPartyIframe
  def allow_outlook_iframe
    if referer_params == "outlook.office365.com" || referer_params == "outlook.office.com"
      # referer = session[:office365_outlook] ? session[:office365_outlook] : referer_params

      response.headers['X-Frame-Options'] = "ALLOW-FROM https://#{referer_params}"

      # session[:office365_outlook] = referer
    end


    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' office.com *.office.com office365.com *.office365.com"
  end

  def allow_sharepoint_iframe
    Rails.logger.info "AppController#allow_iframe: referer: #{request.referer}"
    return if referer_params.blank?

    uri = referer_params#URI.parse(params[:referrer])
    uri = "https://#{uri}" unless uri.match(/https:\/\//) || uri.match(/http:\/\//)
    uri = URI.parse(uri)

    if uri.host.match(/\.sharepoint.com$/) || CompanyDomain.where(domain: uri.host).exists?
      # url = "https://#{uri.host}"
      # Rails.logger.info "AppController#allow_iframe: ALLOW-FROM #{url}"
      if !current_user || current_user.company.domains.map(&:domain).map(&:downcase).include?(uri.host.downcase)
        # FIXME: this protects all logged in pages by matching against referrer param domain
        #        against currently logged in user's company's set of domains
        #        Logged out pages, such as login form is insecure and should be fixed. 
        #        Also, this should be improved by adding security token.
        response.headers.except! 'X-Frame-Options'
      elsif uri.host.match(/\.sharepoint.com$/)
        response.headers['X-Frame-Options'] = "ALLOW_FRAME #{uri.host}"        
      end
      #response.headers['X-Frame-Options'] = "ALLOW-FROM #{url}"
    end
  end

  def allow_yammer_iframe
    response.headers['X-Frame-Options'] = 'ALLOW-FROM https://www.yammer.com'
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' office.com *.office.com office365.com *.office365.com yammer.com *.yammer.com sharepoint.com *.sharepoint.com"
  end

  def allow_intranet_iframe
    allow_sharepoint_iframe
  end

  def allow_chrome_ext_iframe
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' chrome-extension://*"
  end

  def allow_fb_workplace_iframe
    # fb_iframe_origin comes as a param straight from Workplace when clicking a button like "Rewards"
    # Clicking items from the hamburger menu, goes through fb_workplace_placeholder which maps
    # fb_iframe_origin to referrer attribute
    allow_from_domain = params[:fb_iframe_origin] || params[:referrer] || "facebook.com"
    response.headers['X-Frame-Options'] = "ALLOW-FROM #{allow_from_domain}"
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' *.facebook.com *.messenger.com *.workplace.com"
  end

  def allow_ms_teams_iframe
    allow_from_domain = params[:referrer] || "https://teams.microsoft.com"
    response.headers['X-Frame-Options'] = "ALLOW-FROM #{allow_from_domain}"
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' *.microsoft.com *.office.com *.office.net"
  end

  private

  def referer_params
    params[:referrer]
  end
end

