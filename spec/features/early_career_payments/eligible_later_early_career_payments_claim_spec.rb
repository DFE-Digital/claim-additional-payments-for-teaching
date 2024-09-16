require "rails_helper"

RSpec.feature "Eligible later Teacher Early-Career Payments" do
  extend ActionView::Helpers::NumberHelper

  describe "claim" do
    let(:current_school) { create(:school, :early_career_payments_eligible) }
    let(:itt_subject) { "mathematics" }
    let(:journey_session) do
      Journeys::AdditionalPaymentsForTeaching::Session.order(:created_at).last
    end

    context "policy year 2022/2023" do
      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2022),
        itt_academic_year: AcademicYear.new(2018),
        next_eligible_year: AcademicYear.new(2023),
        qualification: "undergraduate_itt"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2022),
        itt_academic_year: AcademicYear.new(2018),
        next_eligible_year: AcademicYear.new(2023),
        qualification: "postgraduate_itt"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2022),
        itt_academic_year: AcademicYear.new(2018),
        next_eligible_year: AcademicYear.new(2023),
        qualification: "assessment_only"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2022),
        itt_academic_year: AcademicYear.new(2018),
        next_eligible_year: AcademicYear.new(2023),
        qualification: "overseas_recognition"
      }
    end

    context "policy year 2023/2024" do
      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2023),
        itt_academic_year: AcademicYear.new(2019),
        next_eligible_year: AcademicYear.new(2024),
        qualification: "undergraduate_itt"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2023),
        itt_academic_year: AcademicYear.new(2019),
        next_eligible_year: AcademicYear.new(2024),
        qualification: "postgraduate_itt"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2023),
        itt_academic_year: AcademicYear.new(2019),
        next_eligible_year: AcademicYear.new(2024),
        qualification: "assessment_only"
      }

      it_behaves_like "Eligible later", {
        policy_year: AcademicYear.new(2023),
        itt_academic_year: AcademicYear.new(2019),
        next_eligible_year: AcademicYear.new(2024),
        qualification: "overseas_recognition"
      }
    end
  end
end
