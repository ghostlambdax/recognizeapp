module DateTimeHelper
  include ActionView::Helpers::TranslationHelper

  def localize_datetime(datetime, format = :slash_date)
    return datetime unless datetime.respond_to?(:strftime)
    l(datetime, format: format)
  end

  def r_years_since(from_d, d = DateTime.now)
    # Difference in years, less one if you have not had a previous date this year.
    years_since = d.year - from_d.year
    years_since -= 1 if from_d.month > d.month# || from_d.month >= d.month & from_d.day > d.day
    years_since
  end
end
