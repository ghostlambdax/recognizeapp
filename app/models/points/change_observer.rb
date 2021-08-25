class Points::ChangeObserver < ActiveRecord::Observer
  observe :recognition_approval, :redemption

  def after_create(obj)
    PointActivity::Recorder.record!(obj)
  end

  def after_destroy(obj)
    PointActivity::Destroyer.destroy!(obj)
  end
end
