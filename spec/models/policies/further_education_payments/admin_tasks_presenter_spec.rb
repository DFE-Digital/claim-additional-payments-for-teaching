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
          rows = subject.provider_verification_rows
          continued_employment_row = rows.find { |row| row[0] == "Continued employment" }
          expect(continued_employment_row).to eql(["Continued employment", "N/A", "Yes"])
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
          rows = subject.provider_verification_rows
          continued_employment_row = rows.find { |row| row[0] == "Continued employment" }
          expect(continued_employment_row).to eql(["Continued employment", "N/A", "No"])
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
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: {
            teaching_hours_per_week: "12_to_20_hours_per_week"
          }
        )

        rows = described_class.new(claim).provider_verification_rows

        expect(rows).to include(["Teaching responsibilities", "Yes", "Yes"])

        expect(rows).to include([
          "First 5 years of teaching",
          AcademicYear.new(2023),
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
          "12 or more hours per week, but fewer than 20",
          "20 hours or more per week"
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
  end
end
