class CustomTheme
  attr_reader :company

  DIGEST_CACHE_KEY = "company-theme-digest-"
  IN_PROGRESS_CACHE_KEY = "company-theme-compilation-in-progress"

  def self.compile_all_company_themes!
    Company.where(has_theme: true).each do |c|
      CustomTheme.delay(queue: 'themes').compile_theme!(c.id) if c.has_theme?
    end
  end

  def self.signature(method_name, args)
    # CustomTheme#compile_theme!-<company_id>
    "CustomTheme#compile_theme!-#{args[0]}"
  end

  def self.compile_theme!(company_id)
    ct = new(Company.find(company_id))
    ct.compile!
  end

  def self.valid_sheet?(stylesheet)
    return false if stylesheet.blank? || !stylesheet.include?("\n@import \"application\"\;")
    ::Sass::Engine.new(stylesheet.gsub("\n@import \"application\"\;", ''), {syntax: :scss, cache: false, read_cache: false}).render
    return true # for now
  rescue => e
    Rails.logger.debug "----------------------"
    Rails.logger.debug "Stylesheet is invalid: #{e}"
    Rails.logger.debug stylesheet
    Rails.logger.debug "----------------------"
    return false
  end

  def initialize(company)
    @company = company
  end

  def compile!

    "Compiling theme for #{company.domain}"
    Rails.logger.info "Compiling theme for #{company.domain}"
    Rails.cache.write(in_progress_cache_key, true)

    self.write_stylesheet_to_file!

    theme = company.company_theme_id.downcase

    env =  (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application))
    tmp_asset_name = "themes/#{theme}"
    asset = env.find_asset(tmp_asset_name)

    if asset.blank?
      puts "Skipping #{company.domain} because no stylesheet found"
      Rails.logger.info "Skipping #{company.domain} because no stylesheet found"
      return
    end

    compressed_body = ::Sass::Engine.new(asset.source, {:syntax => :scss,:cache => false,:read_cache => false,:style => :compressed}).render
    asset.digest
    asset_path = "assets/themes/#{theme}-#{asset.digest}.css"
    non_digest_path = "assets/themes/#{theme}.css"
    full_asset_path = File.join(Rails.root, 'public', asset_path)
    full_non_digest_path = File.join(Rails.root, 'public', non_digest_path)
    dir = File.dirname(full_asset_path)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    File.open(full_asset_path, 'w') { |f| f.write(compressed_body) }
    File.open(full_non_digest_path, 'w') { |f| f.write(compressed_body) }

    # update Sprockets digest manifest
    assets_manifest = Rails.application.assets_manifest
    assets_manifest.assets["themes/#{theme}.css"] = "themes/#{theme}-#{asset.digest}.css"
    path = assets_manifest.path

    json = assets_manifest.instance_variable_get("@data").to_json
    File.open(path, 'w+'){|f| f.write(json)}
    Rails.cache.write(digest_cache_key, asset.digest)
    Rails.cache.delete(in_progress_cache_key)
    company.update_column(:has_theme, true) unless company.has_theme?
  end

  def asset_name
    # there should always be a digest
    # but in case there isn't fallback to non-digested asset
    if ActionController::Base.asset_host.present? && digest.present?
      "#{company.company_theme_id}-#{digest}"
    else
      company.company_theme_id
    end
  end

  def asset_url
    if Delayed::Job.where(queue: 'themes').exists? || $redis.get('skip_cloudfront_for_custom_themes')
      return "https://#{Rails.application.config.host}/assets/themes/#{asset_name}.css"
    else
      ActionController::Base.asset_host.present? ?
        "#{ActionController::Base.asset_host}/assets/themes/#{asset_name}.css" :
        "themes/#{asset_name}"
    end
  end

  def compiling_in_progress?
    # NOTE: this method used to be so that we would disable a theme when compiling is in progress
    #             However, I think this is unnecessary, because themes are loaded with a digest
    #             And the digest value will be updated in cache once compiling is complete.
    # theme_compilation_queued? ||
    # Rails.cache.read(in_progress_cache_key)
    return false
  end

  def theme_compilation_queued?
    Delayed::Job.where(signature: "CustomTheme#compile_theme!-#{self.company.id}", failed_at: nil, locked_at: nil).size > 0
  end

  def digest
    Rails.cache.read(digest_cache_key)
  end

  def digest_cache_key
    "#{DIGEST_CACHE_KEY}-#{company.id}"
  end

  def in_progress_cache_key
    "#{IN_PROGRESS_CACHE_KEY}-#{company.id}"
  end

  def write_stylesheet_to_file!
    return unless (styles = company.customizations&.stylesheet).present?
    base_dir = File.join(Rails.root, "app/assets/stylesheets/themes")
    theme = company.company_theme_id
    File.open("#{base_dir}/#{theme}.scss", 'w') do |f|
      f.write(styles)
    end
  end

  def legacy?
    company.has_theme? && !company.customizations&.stylesheet.present?
  end
end
