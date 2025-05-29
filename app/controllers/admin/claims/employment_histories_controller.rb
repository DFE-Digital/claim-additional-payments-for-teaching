module Admin
  module Claims
    class EmploymentHistoriesController < Admin::BaseAdminController
      before_action :ensure_service_operator

      def new
        @form = CreateEmploymentHistoryForm.new(claim)
      end

      def create
        @form = CreateEmploymentHistoryForm.new(claim, params: employment_form_params)

        if @form.save
          redirect_to admin_claim_task_path(claim, "employment_history")
        else
          render :new
        end
      end

      private

      def employment_form_params
        params.require(CreateEmploymentHistoryForm.model_name.param_key).permit(
          :school_id,
          :school_search,
          :employment_contract_of_at_least_one_year,
          :employment_start_date,
          :employment_end_date,
          :met_minimum_teaching_hours,
          :subject_employed_to_teach
        )
      end

      def claim
        @claim ||= Claim.find(params[:claim_id])
      end
    end
  end
end
