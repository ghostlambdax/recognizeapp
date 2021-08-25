# frozen_string_literal: true

# NOTE: this code may be problematic for
#       Rails 5.2 upgrade.
# https://github.com/rails/rails/issues/32557
# https://bugs.chromium.org/p/chromium/issues/detail?id=516846
# https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching
module HttpCacheConcern
  def ensure_no_cache!
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end
end
