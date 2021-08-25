module GonHelper
  def set_gon_attributes_for_recognition_delete_swal
    gon.translations_for_recognition_delete_swal = {
        title: I18n.t("swal.are_you_sure"),
        label: I18n.t("recognitions.delete_for_swal"),
        confirm_text: I18n.t("swal.delete_confirm"),
        cancel_text: I18n.t("swal.cancel")
    }
  end

  def set_gon_team_counts
    gon.team_counts = @company.team_to_member_count_map
  end
end