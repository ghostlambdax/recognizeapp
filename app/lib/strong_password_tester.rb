class StrongPasswordTester < PasswordStrength::Base
  def test
    if additional_criteria_passed?
      super
    else
      invalid!
    end
  end

  private

  def additional_criteria_passed?
    email_not_included?
  end

  def email_not_included?
    return true if record.email.blank? || !password.include?(record.email)

    record.errors.add(:password, I18n.t("activerecord.errors.models.user.password.username_email_included"))
    false
  end
end
