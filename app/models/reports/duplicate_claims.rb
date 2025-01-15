require "csv"
require "excel_utils"

module Reports
  class DuplicateClaims
    include Admin::ClaimsHelper

    NAME = "Duplicate Approved Claims"
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Full name",
      "Policy name",
      "Claim amount",
      "Claim status",
      "Decision date",
      "Decision agent"
    ].freeze

    def initialize
      @claims = Claim.approved.select { |claim| Claim::MatchingAttributeFinder.new(claim).matching_claims.any? }
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << ClaimPresenter.new(claim).to_a
        end
      end
    end

    private

    class ClaimPresenter
      include Admin::ClaimsHelper
      include ActionView::Helpers::NumberHelper

      def initialize(claim)
        @claim = claim
      end

      def to_a
        [
          claim.reference,
          claim.eligibility.try(:teacher_reference_number),
          claim.full_name,
          claim.policy,
          claim.award_amount,
          status(claim),
          claim.latest_decision&.created_at,
          claim.latest_decision&.created_by&.full_name
        ]
      end

      private

      attr_reader :claim
    end
  end
end
