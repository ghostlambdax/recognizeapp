class Api::V2::Endpoints::Approvals::Index < Api::V2::Endpoints::Approvals
  resources :approvals, controller: :recognition_approvals, desc: '' do
    desc 'Returns likes for a company' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      optional :recognition_id, type: String, desc: "Recognition ID"
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      if(params[:recognition_id].present?)
        approvals = current_user.company.recognitions.find_from_param!(params[:recognition_id]).approvals
      else
        approvals = RecognitionApproval.where(recognition_id: current_user.company.recognitions.pluck(:id))
      end
      paged = paginate(approvals)
      present paged
    end
  end
end
