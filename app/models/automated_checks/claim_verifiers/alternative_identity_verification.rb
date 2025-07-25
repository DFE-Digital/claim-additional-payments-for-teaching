module AutomatedChecks
  module ClaimVerifiers
    class AlternativeIdentityVerification
      TASK_NAME = "alternative_identity_verification".freeze

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return unless eligibility.claimant_identity_verified_at?
        return if task_exists?
        return unless all_details_match?

        create_task!
      end

      private

      attr_reader :claim

      delegate :eligibility, to: :claim

      def create_task!
        task = claim.tasks.build(
          name: TASK_NAME,
          manual: false,
          passed: true,
          claim_verifier_match: "all",
          created_by: created_by
        )

        task.save!(context: :claim_verifier)

        task
      end

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def all_details_match?
        postcodes_match? &&
          national_insurance_numbers_match? &&
          dates_of_birth_match? &&
          passports_match?
      end

      def postcodes_match?
        normalise(claim.postcode) == normalise(eligibility.claimant_postcode)
      end

      def national_insurance_numbers_match?
        normalise(claim.national_insurance_number) ==
          normalise(eligibility.claimant_national_insurance_number)
      end

      def dates_of_birth_match?
        claim.date_of_birth == eligibility.claimant_date_of_birth
      end

      def passports_match?
        # If both parties say they don't have a passport, don't compare passport
        # numbers.
        if !eligibility.valid_passport? && !eligibility.claimant_valid_passport?
          return true
        end

        eligibility.valid_passport? == eligibility.claimant_valid_passport? &&
          normalise(eligibility.passport_number) ==
            normalise(eligibility.claimant_passport_number)
      end

      def normalise(string)
        string.to_s.remove(/\s/).downcase
      end

      def verifier
        claim.eligibility.verification.fetch("verifier")
      end

      def created_by
        DfeSignIn::User.find_or_create_by!(dfe_sign_in_id: verifier.fetch("dfe_sign_in_uid"), user_type: "provider") do |user|
          user.given_name = verifier.fetch("first_name")
          user.family_name = verifier.fetch("last_name")
          user.email = verifier.fetch("email")
          user.organisation_name = verifier.fetch("dfe_sign_in_organisation_name")
          user.role_codes = verifier.fetch("dfe_sign_in_role_codes")
        end
      end
    end
  end
end
