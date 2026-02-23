require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::EligibilityAdminProviderAnswersPresenter do
  let(:presenter) { described_class.new(eligibility) }

  let(:school) do
    create(
      :school,
      :further_education,
      :fe_eligible,
      name: "Springfield Elementary"
    )
  end

  let(:claim) do
    create(
      :claim,
      academic_year: AcademicYear.new(2025),
      first_name: "Edna",
      surname: "Krabappel"
    )
  end

  describe "#provider_employment_check" do
    subject { presenter.provider_employment_check }

    context "when provider verification not completed" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it { is_expected.to be_nil }
    end

    context "when employment not checked" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it { is_expected.to be_nil }
    end

    context "when claimant is not employed by the college" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_employment_checked_claimant_not_employed_by_college,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it do
        is_expected.to eq([
          [
            "Does Springfield Elementary employ Edna Krabappel?",
            "No"
          ],
          [
            "Enter their date of birth",
            "Not answered"
          ],
          [
            "Enter their National Insurance number",
            "Not answered"
          ],
          [
            "Do these bank details match what you have for Edna Krabappel?",
            "Not answered"
          ],
          [
            "Email address",
            "Not answered"
          ]
        ])
      end
    end

    context "when provider verification completed and employment checked" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :provider_verification_employment_checked,
          :eligible,
          claim: claim,
          school: school,
          provider_verification_claimant_email: "edna.k@springfield-elementary.edu",
          provider_verification_claimant_date_of_birth: Date.new(1956, 3, 15)
        )
      end

      it do
        is_expected.to match_array([
          [
            "Does Springfield Elementary employ Edna Krabappel?",
            "Yes"
          ],
          [
            "Enter their date of birth",
            "15 March 1956"
          ],
          [
            "Enter their National Insurance number",
            "AB123456C"
          ],
          [
            "Do these bank details match what you have for Edna Krabappel?",
            "Yes"
          ],
          [
            "Email address",
            "edna.k@springfield-elementary.edu"
          ]
        ])
      end
    end
  end

  describe "#provider_details" do
    subject { presenter.provider_details }

    context "when provider verification not completed" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it { is_expected.to be_nil }
    end

    context "when claimant is not employed by the college" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_employment_checked_claimant_not_employed_by_college,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it { is_expected.to be_nil }
    end

    context "when provider verification completed" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :eligible,
          claim: claim,
          school: school
        )
      end

      it do
        is_expected.to match_array([
          [
            "Is Edna Krabappel a member of staff with the responsibilities of a teacher?",
            "Yes"
          ],
          [
            "Edna Krabappel has indicated that they began their FE teaching " \
            "career in England during September 2023 to August 2024. Please " \
            "confirm the academic year in which Edna Krabappel actually " \
            "started their FE teaching career in England.",
            "September 2023 to August 2024"
          ],
          [
            "Does Edna Krabappel have a teaching qualification?",
            "Yes"
          ],
          [
            "Edna Krabappel said last year that they planned to " \
            "start a teaching qualification within 12 months. They’ve " \
            "confirmed the same intention in their application this year. Tell " \
            "us why they have not yet started or finished a teaching qualification",
            "Not answered"
          ],
          [
            "What type of contract does Edna Krabappel have directly with Springfield Elementary?",
            "Fixed-term"
          ],
          [
            "Does Edna Krabappel have a fixed-term contract " \
            "for the full 2025 to 2026 academic year?",
            "Yes"
          ],
          [
            "Has Edna Krabappel worked at Springfield Elementary for the full spring term?",
            "Not answered"
          ],
          [
            "Is Edna Krabappel currently subject to any " \
            "formal performance measures as a result of continuous poor " \
            "teaching standards?",
            "No"
          ],
          [
            "Is Edna Krabappel currently subject to any disciplinary action?",
            "No"
          ],
          [
            "On average, how many hours per week was Edna Krabappel timetabled to teach at Springfield Elementary during the spring term?",
            "20 hours or more per week"
          ],
          [
            "Did Edna Krabappel spend at least half of their " \
            "timetabled teaching hours teaching students on 16 to 19 study " \
            "programmes, T Levels or 16 to 19 apprenticeships?",
            "Yes"
          ],
          [
            "During the spring term, did Edna Krabappel spend at least half of their timetabled teaching hours teaching these courses?",
            "Yes"
          ],
          [
            "Is Edna Krabappel expected to work at Springfield Elementary or another eligible FE provider until the end of the academic year?",
            "Yes"
          ]
        ])
      end
    end

    context "when the not started qualification question is answered" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :eligible,
          claim: claim,
          school: school,
          provider_verification_not_started_qualification_reasons: %w[
            workload
            funding_issues
          ]
        )
      end

      it do
        is_expected.to include([
          "Edna Krabappel said last year that they planned to " \
          "start a teaching qualification within 12 months. They’ve " \
          "confirmed the same intention in their application this year. Tell " \
          "us why they have not yet started or finished a teaching qualification",
          "Workload, Funding issues"
        ])
      end
    end

    context "when the not started qualification question is answered with other" do
      let(:eligibility) do
        create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          :eligible,
          claim: claim,
          school: school,
          provider_verification_not_started_qualification_reasons: %w[
            other
          ],
          provider_verification_not_started_qualification_reason_other: "Their dog needed walking"
        )
      end

      it do
        is_expected.to include([
          "Edna Krabappel said last year that they planned to " \
          "start a teaching qualification within 12 months. They’ve " \
          "confirmed the same intention in their application this year. Tell " \
          "us why they have not yet started or finished a teaching qualification",
          "Their dog needed walking"
        ])
      end
    end
  end
end
