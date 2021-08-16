module AddressDetails
  extend ActiveSupport::Concern

  included do
    before_action :check_session_for_postcode_not_found, only: [:show]
    before_action :split_full_address_to_parts, only: [:update], if: -> { params[:slug] == "select-home-address" }
  end

  private

  def address_data
    if postcode.present? && params[:claim][:address_line_1].present?
      return @address_data = OrdnanceSurvey::Client.new.api.search_places.show(
        params: {address_line_1: params[:claim][:address_line_1], postcode: postcode}
      )
    end

    if postcode.present?
      @address_data = OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode: postcode}
      )
    end
  end

  def check_session_for_postcode_not_found
    if session[:postcode_not_found]
      current_claim.errors.add(:postcode, session[:postcode_not_found])
      session[:postcode_not_found] = nil
    end
  end

  def invalid_postcode?
    if postcode.blank? || !UKPostcode.parse(postcode).full_valid?
      invalid_postcode
      return true
    end
    false
  end

  def invalid_postcode
    current_claim.errors.add(:postcode, "Enter a real postcode")
  end

  def postcode
    params.dig(:claim, :postcode)
  end

  def split_full_address_to_parts
    address_parts = params[:address].split(":")
    full_address = address_parts[0].split(",")

    current_claim.postcode = full_address.pop.strip
    current_claim.address_line_3 = full_address.pop.strip
    current_claim.address_line_2 = full_address.pop.strip
    current_claim.address_line_1 = full_address.join(",").strip
  end
end
