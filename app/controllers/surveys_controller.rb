class SurveysController < ApplicationController
  def create
    @survey = Survey.create!(Hashie::Mash.new(survey_params.to_h))
    respond_with(@survey)
  end

  def survey_params
    params
      .require(:survey)
      .permit(:email, data: %i[name
                               company_name
                               industry
                               num_of_users
                               title
                               full_name
                               value_1
                               value_2
                               value_3
                               value_4
                               value_5
                               value_6
                               rewards_budget
                               reward_exp
                               reward_gifts
                               reward_nonmonetary
                               reward_system])
  end
end