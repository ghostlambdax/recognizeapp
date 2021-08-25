class Middleware::DevImageIgnorer
  def initialize(app)
    @app = app
  end

  def call(env)
    @env = env
    if path.match(/uploads.development/) && image_is_missing?
      [204, {"Content-Type" => "text/plain"}, ""]
    else
      @app.call(@env)
    end
  end

  def image_is_missing?
    # check file is missing in public directory
    !File.exist?("#{Rails.root}/public#{path}")
  end

  def path
    @env['PATH_INFO']
  end
end
