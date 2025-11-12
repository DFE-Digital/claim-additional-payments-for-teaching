require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::AdminTasksPresenter do
  describe "#provider_verification_rows" do
    context "continued_employment" do
      subject do
        described_class.new(claim)
      end

      let(:claim) do
        build(
          :claim,
          :further_education,
          eligibility:
        )
      end

      context "when provider answers claimant is" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :provider_verification_completed
          )
        end

        it "returns Yes" do
          expect(subject.provider_verification_rows[10][0]).to eql("Continued employment")
          expect(subject.provider_verification_rows[10][1]).to eql("N/A")
          expect(subject.provider_verification_rows[10][2]).to eql("Yes")
        end
      end

      context "when provider answers claimant is not" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :provider_verification_completed,
            provider_verification_continued_employment: false
          )
        end

        it "returns No" do
          expect(subject.provider_verification_rows[10][0]).to eql("Continued employment")
          expect(subject.provider_verification_rows[10][1]).to eql("N/A")
          expect(subject.provider_verification_rows[10][2]).to eql("No")
        end
      end
    end

    context "when the provider has not submitted verification" do
      it "returns an empty array" do
        claim = create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_attributes: {
            provider_verification_completed_at: nil
          }
        )

        expect(described_class.new(claim).provider_verification_rows).to eq []
      end
    end

    context "when the provider has submitted verification" do
      it "returns an array of verification rows" do
        claim = create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed]
        )

        rows = described_class.new(claim).provider_verification_rows

        expect(rows).to include(["Teaching responsibilities", "Yes", "Yes"])

        expect(rows).to include([
          "First 5 years of teaching",
          "September 2023 to 2024",
          "Yes"
        ])

        expect(rows).to include(["Teaching qualification", "Yes", "Yes"])

        expect(rows).to include([
          "Contract of employment",
          "Permanent",
          "Fixed-term"
        ])

        expect(rows).to include([
          "Timetabled teaching hours",
          "12 or more hours per week",
          "12 or more hours per week"
        ])

        expect(rows).to include(["Age range taught", "Yes", "Yes"])

        expect(rows).to include([
          "Subject",
          "Maths<br><br>Physics",
          "Yes"
        ])

        expect(rows).to include([
          "Course",
          "Qualifications approved for funding at level 3 and below in the <a class=\"govuk-link\" target=\"_blank\" rel=\"noreferrer noopener\" href=\"https://www.qualifications.education.gov.uk/Search?Status=All&amp;Level=0,1,2,3,4&amp;Sub=28&amp;PageSize=10&amp;Sort=Status\">mathematics and statistics (opens in new tab)</a> sector subject area<br><br>GCSE in maths, functional skills qualifications and <a class=\"govuk-link\" target=\"_blank\" rel=\"noreferrer noopener\" href=\"https://submit-learner-data.service.gov.uk/find-a-learning-aim/\">other maths qualifications (opens in new tab)</a> approved for teaching to 16 to 19-year-olds who meet the condition of funding<br><br>GCSE physics",
          "Yes"
        ])

        expect(rows).to include(["Subject to performance measures", "No", "No"])

        expect(rows).to include(["Subject to disciplinary action", "No", "No"])
      end

      it "returns the reason for not enrolling if applicable" do
        claim = create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: {
            provider_verification_teaching_qualification: "no_but_planned",
            provider_verification_not_started_qualification_reasons: ["no_valid_reason"]
          }
        )

        rows = described_class.new(claim).provider_verification_rows

        expect(rows).to include([
          "Reason for not enrolling",
          "N/A",
          "No valid reason"
        ])
      end
    end

    describe "timetabled_teaching_hours" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: eligibility_attributes
        )
      end

      describe "provider answers" do
        subject do
          described_class
            .new(claim)
            .provider_verification_rows[6]
            .last
        end

        context "when provider answers 'more_than_20" do
          let(:eligibility_attributes) do
            {
              provider_verification_teaching_hours_per_week: "more_than_20"
            }
          end

          it { is_expected.to eq("12 or more hours per week") }
        end

        context "when provider answers 'more_than_12" do
          let(:eligibility_attributes) do
            {
              provider_verification_teaching_hours_per_week: "more_than_12"
            }
          end

          it { is_expected.to eq("12 or more hours per week") }
        end

        context "when provider answers 'between_2_5_and_12'" do
          let(:eligibility_attributes) do
            {
              provider_verification_teaching_hours_per_week: "between_2_5_and_12"
            }
          end

          it { is_expected.to eq("2.5 or more hours per week, but fewer than 12") }
        end

        context "when provider answers 'less_than_2_5'" do
          let(:eligibility_attributes) do
            {
              provider_verification_teaching_hours_per_week: "less_than_2_5"
            }
          end

          it { is_expected.to eq("Fewer than 2.5 hours each week") }
        end
      end
    end

    describe "fixed_term_full_year" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: eligibility_attributes
        )
      end

      subject do
        described_class
          .new(claim)
          .provider_verification_rows
          .detect { it.first == "Full academic year" }
      end

      # Only asked for fixed-term contracts
      context "when the claimant hasn't answered that question" do
        let(:eligibility_attributes) do
          {
            contract_type: "permanent"
          }
        end

        it { is_expected.to be_nil }
      end

      context "when the claimant has answered that question" do
        let(:eligibility_attributes) do
          {
            contract_type: "fixed_term",
            fixed_term_full_year: false,
            provider_verification_contract_covers_full_academic_year: false
          }
        end

        it do
          is_expected.to eq([
            "Full academic year",
            "No",
            "No"
          ])
        end
      end
    end

    describe "taught_at_least_one_term" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: eligibility_attributes
        )
      end

      subject do
        described_class
          .new(claim)
          .provider_verification_rows
          .detect { it.first == "Taught at least one term" }
      end

      # Only asked for fixed-term contracts that don't cover full year
      context "when the claimant hasn't answered that question" do
        let(:eligibility_attributes) do
          {
            contract_type: "fixed_term",
            fixed_term_full_year: true
          }
        end

        it { is_expected.to be_nil }
      end

      context "when the claimant has answered that question" do
        let(:eligibility_attributes) do
          {
            contract_type: "fixed_term",
            fixed_term_full_year: false,
            taught_at_least_one_term: true,
            provider_verification_taught_at_least_one_academic_term: true
          }
        end

        it do
          is_expected.to eq([
            "Taught at least one term",
            "Yes",
            "Yes"
          ])
        end
      end
    end
  end
end
