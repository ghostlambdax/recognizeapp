class ConvertTaskValueToPoints < ActiveRecord::Migration[5.0]
  def change
    # create points columns
    add_column :tasks, :points, :integer
    add_column :completed_tasks, :points, :integer

    # populate points column from value column & ptc ratio
    reversible do |direction|
      direction.up { populate_task_points_from_value }
    end
  end

  private

  def populate_task_points_from_value
    safe_run_for_each_company_with_ptc_ratio do |company, ptc_ratio|
      company.tasks.update_all("points = value * #{ptc_ratio}")
      company.completed_tasks.update_all("points = value * #{ptc_ratio}")
    end
  end

  def original_ptc_ratio(company)
    # sorting in ruby, because catalogs are already loaded
    company.catalogs.min_by(&:created_at).points_to_currency_ratio
  end

  def safe_run_for_each_company_with_ptc_ratio
    Company.includes(:catalogs).find_each do |company|
      if company.catalogs.size.positive?
        yield(company, original_ptc_ratio(company))
      else
        log("No catalog found for company: #{company.name}, skipping.")
      end
    rescue => e
      log("Caught Exception: #{e} (company: #{company.name})")
    end
  end

  def log(message)
    puts message
    Rails.logger.warn(message)
  end
end
