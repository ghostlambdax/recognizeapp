class Api::V2::Endpoints::Users < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    root 'users', 'user'
    expose :first_name, documentation: { type: String, description: 'First name'}
    expose :last_name, documentation: { type: String, description: 'Last name'}
    expose :email, documentation: { type: String, description: 'Email address'}
    expose :label, documentation: { type: String, description: 'Label to use for user. Will show name, if not email'}
    expose :avatar_thumb_url, as: :avatar_url, documentation: { type: String, description: 'Avatar url'}, if: lambda{|user, options|  user.id.present?}
    expose :network, documentation: { type: String, description: 'Network this user belongs to'}
    expose :status, documentation: { type: String, description: 'Status of the user'}
    expose :total_points, documentation: {type: String, description: 'Total points earned by the user'}
    expose :interval_points, documentation: {type: String, description: 'Total points earned by the user in the company\'s point reset interval'}
    expose :interval_label, documentation: {type: String, description: 'The interval label which encompasses the users interval points. Eg. "quarter", or "month"'}
    expose :redeemable_points, documentation: {type: String, description: 'Total points earned that are eligible for redeeming rewards'}
    expose :can_post_to_yammer_wall?, as: :can_post_to_yammer_wall, documentation: {type: 'boolean', description: 'Whether the user has the ability to post recognitions to Yammer wall'}
    expose :can_post_to_fb_workplace?, as: :can_post_to_workplace, documentation: {type: 'boolean', description: 'Whether the user has the ability to post to Workplace by Facebook'}
    expose :can_post_private_recognitions?, as: :can_post_private_recognitions, documentation: {type: 'boolean', description: 'Whether the user has the ability to post to Workplace by Facebook'}
    expose :can_view_rewards?, as: :can_view_rewards, documentation: {type: 'boolean', description: 'Whether a user has the ability to view rewards.'}
    expose :can_view_comments?, as: :can_view_comments, documentation: { type: 'boolean', description: 'Whether a user has the ability to view comments.' }
    expose :job_title, documentation: {type: String, description: "Job title"}
    expose :can_view_points
    expose :employee_id, documentation: { type: String, description: 'Employee ID' }
    
    def can_view_points
      !object.company.hide_points?
    end
  end


  # mount Api::V2::Endpoints::Users::Index
  mount Api::V2::Endpoints::Users::Create
  mount Api::V2::Endpoints::Users::Destroy
  mount Api::V2::Endpoints::Users::Search
  mount Api::V2::Endpoints::Users::Show
  mount Api::V2::Endpoints::Users::Import
  mount Api::V2::Endpoints::Users::Redemptions
  mount Api::V2::Endpoints::Users::Recognitions

end
