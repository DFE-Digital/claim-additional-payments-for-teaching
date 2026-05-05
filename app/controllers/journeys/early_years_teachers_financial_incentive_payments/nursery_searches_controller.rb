module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NurserySearchesController < BasePublicController
      def create
        form = NurserySearchForm.new(
          journey: journey,
          journey_session: journey_session,
          params: search_params
        )

        if form.valid?
          render json: {data: form.results}.to_json
        else
          render json: form.errors.to_json, status: :bad_request
        end
      end

      private

      def search_params
        ActionController::Parameters.new(
          NurserySearchForm.model_name.param_key => {
            nursery_search_query: params[:query]
          }
        )
      end
    end
  end
end
