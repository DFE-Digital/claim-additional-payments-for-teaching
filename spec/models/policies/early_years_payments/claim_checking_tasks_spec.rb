require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::ClaimCheckingTasks do
  subject { described_class.new(claim) }

  describe "#applicable_task_names" do
    describe "employment task" do
      let(:claim) do
        build(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      it "includes employment task" do
        expect(subject.applicable_task_names).to include("employment")
      end
    end

    describe "ey_alternative_verification task" do
      let(:claim) do
        build(
          :claim,
          policy: Policies::EarlyYearsPayments,
          onelogin_idv_at: DateTime.new(2025, 7, 1),
          identity_confirmed_with_onelogin: identity_confirmed_with_onelogin,
          academic_year: academic_year
        )
      end

      context "when the claim passed one login idv" do
        let(:identity_confirmed_with_onelogin) { true }
        let(:academic_year) { AcademicYear.new("2025/2026") }

        it "does not include the task" do
          expect(subject.applicable_task_names).not_to include(
            "ey_alternative_verification"
          )
        end
      end

      context "when the claim failed one login idv" do
        let(:identity_confirmed_with_onelogin) { false }

        context "when a year 1 claim" do
          let(:academic_year) { AcademicYear.new("2024/2025") }

          it "does not include the task" do
            expect(subject.applicable_task_names).not_to include(
              "ey_alternative_verification"
            )
          end
        end

        context "when not a year 1 claim" do
          let(:academic_year) { AcademicYear.new("2025/2026") }

          it "includes the task" do
            expect(subject.applicable_task_names).to include(
              "ey_alternative_verification"
            )
          end
        end
      end
    end
  end
end
