class SchoolSearchController < ApplicationController
  include DfE::Analytics::Requests
  include HttpAuthConcern

  def create
    search_schools

    if errors.blank?
      render(
        json: {
          data: @schools.map do |school|
            {
              id: school.id,
              name: school.name,
              address: school.address,
              closeDate: school.closed? ? I18n.l(school.close_date) : nil
            }
          end
        }
      )
    else
      render json: {errors: errors}, status: :bad_request
    end
  end

  private

  def search_schools
    if params[:query].blank?
      errors.push("Expected required parameter 'query' to be set")
      return
    end

    fe_only = ActiveModel::Type::Boolean.new.cast(params[:fe_only])
    schools = ActiveModel::Type::Boolean.new.cast(params[:exclude_closed]) ? School.open : School

    begin
      @schools = schools.search(params[:query], fe_only:)
    rescue ArgumentError => e
      raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

      errors.push(School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR)
    end
  end

  def errors
    @errors ||= []
  end
  helper_method :errors
end
