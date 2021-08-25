# FIXME: move this to datatables folder
class RecognitionReportSerializer < ActiveModel::Serializer
  attributes :company, :from, :to, :recordsTotal, :recordsFiltered

  has_many :recognitions

  EXPORT_HEADERS = {
    :url => I18n.t('dict.url'),
    :date => I18n.t('forms.date'),
    :sender_name => I18n.t('forms.sender_name'),
    :sender_email => I18n.t('forms.sender_email'),
    :reference_recipient_name => I18n.t('forms.recipient_name'),
    :reference_recipient_email => I18n.t('forms.recipient_email'),
    :teams => I18n.t('forms.teams'),
    :badge => I18n.t('forms.badge'),
    :points => I18n.t('forms.points'),
    :message => I18n.t('forms.message'),
    :recognized_team => I18n.t('forms.recognized_team'),
  }

  # NOTE: There might be a better way to do a replacement on the key,
  #       but this works and is only done once for the class
  EXPORT_VALUE_ALIASES = {teams: :reference_recipient_teams}
  EXPORT_VALUE_KEYS = EXPORT_HEADERS.keys.inject({}){|hash, k| hash[k] = k;hash}.merge(EXPORT_VALUE_ALIASES).values

  def as_json(options = {})
    {
      company: company,
      from: from,
      to: to,
      recordsTotal: recordsTotal,
      recordsFiltered: recordsFiltered,
      data: ActiveModel::ArraySerializer.new(recognitions)
    }
  end

  def company
    object.company.domain
  end

  def from
    object.from
  end

  def to
    object.to
  end

  def recordsTotal
    object.recognition_count
  end

  def recordsFiltered
    object.recognition_count
  end

  def to_csv(opts={})
    json = self.as_json[:recognitions]
    csv_string = CSV.generate(opts) do |csv|
      csv << EXPORT_HEADERS.values
      json.each do |row|
        csv << row.values_at(*EXPORT_VALUE_KEYS)
      end
    end
    csv_string
  end
end
