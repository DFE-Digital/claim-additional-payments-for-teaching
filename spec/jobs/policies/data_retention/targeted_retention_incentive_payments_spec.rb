require "rails_helper"

RSpec.describe Policies::DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
  end

  context "when the policy is TargetedRetentionIncentivePayments" do
    let!(:journey_configuration) do
      create(
        :journey_configuration,
        :targeted_retention_incentive_payments,
        current_academic_year: AcademicYear.new(2024)
      )
    end

    let(:claim_attributes) do
      {
        first_name: "John",
        middle_name: "Michael",
        surname: "Smith",
        date_of_birth: Date.new(1990, 1, 1),
        address_line_1: "1 Test Road",
        address_line_2: "Test Town",
        address_line_3: "Test County",
        address_line_4: "Test Region",
        postcode: "AB1 2CD",
        payroll_gender: "female",
        national_insurance_number: "QQ123456C",
        bank_sort_code: "220011",
        bank_account_number: "12345678",
        building_society_roll_number: "1234567890",
        banking_name: "John Smith",
        hmrc_bank_validation_responses: [{"code" => 200, "body" => "ok"}],
        mobile_number: "07474000123",
        teacher_id_user_info: {"given_name" => "John"},
        dqt_teacher_status: {"trn" => "1234567"},
        email_address: "test@example.com",
        email_verified: true,
        provide_mobile_number: true,
        mobile_verified: true,
        bank_or_building_society: "personal_bank_account",
        has_student_loan: true,
        student_loan_plan: StudentLoan::PLAN_1,
        details_check: true,
        hmrc_bank_validation_succeeded: true,
        held: false,
        qa_required: false,
        submitted_using_slc_data: false
      }
    end

    let(:eligibility_attributes) do
      {
        teacher_reference_number: "1234567",
        award_amount: 2000.0,
        current_school_id: create(:school, :targeted_retention_incentive_payments_eligible).id,
        eligible_itt_subject: "mathematics",
        qualification: "postgraduate_itt",
        itt_academic_year: AcademicYear.new(2023),
        nqt_in_academic_year_after_itt: true,
        teaching_subject_now: true,
        employed_as_supply_teacher: false,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false,
        eligible_degree_subject: true,
        employed_directly: true,
        has_entire_term_contract: true,
        induction_completed: true,
        school_somewhere_else: false
      }
    end

    let(:amendment_changes) do
      {
        "payroll_gender" => ["male", "female"],
        "date_of_birth" => [Date.new(1985, 6, 15), Date.new(1990, 1, 1)],
        "bank_sort_code" => ["111111", "220011"],
        "bank_account_number" => ["87654321", "12345678"],
        "student_loan_plan" => [StudentLoan::PLAN_2, StudentLoan::PLAN_1]
      }
    end

    let(:scrubbed_claim_attributes) do
      %i[
        first_name
        middle_name
        surname
        date_of_birth
        email_address
        address_line_1
        address_line_2
        address_line_3
        address_line_4
        postcode
        national_insurance_number
        bank_sort_code
        bank_account_number
        building_society_roll_number
        banking_name
        hmrc_bank_validation_responses
        mobile_number
        teacher_id_user_info
        dqt_teacher_status
      ]
    end

    let(:scrubbed_amendment_changes) do
      {
        "payroll_gender" => ["male", "female"],
        "date_of_birth" => nil,
        "bank_sort_code" => nil,
        "bank_account_number" => nil,
        "student_loan_plan" => [StudentLoan::PLAN_2, StudentLoan::PLAN_1]
      }
    end

    let(:job_run_date) { Date.new(2031, 11, 1) }

    let(:claim) do
      create(
        :claim,
        :submitted,
        **claim_attributes,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.new(2024),
        eligibility_attributes: eligibility_attributes
      )
    end

    context "when the claim is inactive and at least six academic years old" do
      context "when the claim is rejected" do
        it "scrubs personal data" do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: DateTime.new(2030, 10, 15)
          )

          travel_to(job_run_date) do
            perform_enqueued_jobs { described_class.perform_now }
          end

          claim.reload
          claim.eligibility.reload

          aggregate_failures do
            expect(claim).to(
              have_attributes(scrubbed_claim_attributes.index_with(nil))
            )

            expect(claim).to(
              have_attributes(claim_attributes.except(*scrubbed_claim_attributes))
            )

            expect(claim.eligibility).to have_attributes(
              eligibility_attributes.merge(teacher_reference_number: "")
            )
          end
        end
      end

      context "when the claim is paid" do
        before do
          create(:decision, :approved, claim: claim)
          create(
            :payment,
            :confirmed,
            :with_figures,
            claims: [claim],
            scheduled_payment_date: Date.new(2030, 10, 15)
          )

          travel_to(job_run_date) do
            perform_enqueued_jobs { described_class.perform_now }
          end

          claim.reload
          claim.eligibility.reload
        end

        it "scrubs personal data" do
          aggregate_failures do
            expect(claim).to(
              have_attributes(scrubbed_claim_attributes.index_with(nil))
            )

            expect(claim).to(
              have_attributes(claim_attributes.except(*scrubbed_claim_attributes))
            )

            expect(claim.eligibility).to have_attributes(
              eligibility_attributes.merge(teacher_reference_number: "")
            )
          end
        end

        it "creates a recovery record" do
          recovery = Policies::DataRetention::Recovery.find_by!(claim: claim)

          expect(recovery.payload).to include(
            "claim_attributes" => include(
              "id" => claim.id,
              "first_name" => "John"
            ),
            "eligibility_attributes" => include(
              "id" => claim.eligibility_id,
              "teacher_reference_number" => "1234567"
            )
          )
        end
      end
    end

    context "when the claim is not yet eligible for retention" do
      context "when the claim was rejected in the current academic year" do
        it "retains personal data" do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: DateTime.new(2031, 10, 15)
          )

          travel_to(job_run_date) do
            perform_enqueued_jobs { described_class.perform_now }
          end

          claim.reload

          claim.eligibility.reload

          aggregate_failures do
            expect(claim).to have_attributes(claim_attributes)
            expect(claim.eligibility).to have_attributes(eligibility_attributes)
          end
        end
      end

      context "when the claim was paid in the current academic year" do
        it "retains personal data" do
          create(:decision, :approved, claim: claim)
          create(
            :payment,
            :confirmed,
            :with_figures,
            claims: [claim],
            scheduled_payment_date: Date.new(2031, 10, 15)
          )

          travel_to(job_run_date) do
            perform_enqueued_jobs { described_class.perform_now }
          end

          claim.reload
          claim.eligibility.reload

          aggregate_failures do
            expect(claim).to have_attributes(claim_attributes)
            expect(claim.eligibility).to have_attributes(eligibility_attributes)
          end
        end
      end

      context "when the claim is awaiting a decision" do
        it "retains personal data" do
          travel_to(job_run_date) do
            perform_enqueued_jobs { described_class.perform_now }
          end

          claim.reload
          claim.eligibility.reload

          aggregate_failures do
            expect(claim).to have_attributes(claim_attributes)
            expect(claim.eligibility).to have_attributes(eligibility_attributes)
          end
        end
      end
    end

    context "amendment retention" do
      context "when the claim is inactive and at least six academic years old" do
        context "when the claim is rejected" do
          it "scrubs personal data from the amendment" do
            create(
              :decision,
              :rejected,
              claim: claim,
              created_at: DateTime.new(2030, 10, 15)
            )

            amendment = create(
              :amendment,
              claim: claim,
              claim_changes: amendment_changes
            )

            travel_to(job_run_date) do
              perform_enqueued_jobs { described_class.perform_now }
            end

            amendment.reload

            aggregate_failures do
              expect(amendment).to have_attributes(
                claim_changes: scrubbed_amendment_changes,
                personal_data_removed_at: be_present
              )
            end
          end
        end

        context "when the claim is paid" do
          it "scrubs personal data from the amendment" do
            create(:decision, :approved, claim: claim)
            amendment = create(:amendment, claim: claim, claim_changes: amendment_changes)
            create(
              :payment,
              :confirmed,
              :with_figures,
              claims: [claim],
              scheduled_payment_date: Date.new(2030, 10, 15)
            )

            travel_to(job_run_date) do
              perform_enqueued_jobs { described_class.perform_now }
            end

            amendment.reload

            aggregate_failures do
              expect(amendment).to have_attributes(
                claim_changes: scrubbed_amendment_changes,
                personal_data_removed_at: be_present
              )
            end
          end
        end
      end

      context "when the claim is not yet eligible for retention" do
        context "when the claim was rejected in the current academic year" do
          it "retains personal data in the amendment" do
            create(:decision, :rejected, claim: claim, created_at: DateTime.new(2031, 10, 15))
            amendment = create(:amendment, claim: claim, claim_changes: amendment_changes)

            travel_to(job_run_date) do
              perform_enqueued_jobs { described_class.perform_now }
            end

            amendment.reload

            aggregate_failures do
              expect(amendment).to have_attributes(
                claim_changes: amendment_changes,
                personal_data_removed_at: nil
              )
            end
          end
        end

        context "when the claim was paid in the current academic year" do
          it "retains personal data in the amendment" do
            create(:decision, :approved, claim: claim)
            amendment = create(:amendment, claim: claim, claim_changes: amendment_changes)
            create(
              :payment,
              :confirmed,
              :with_figures,
              claims: [claim],
              scheduled_payment_date: Date.new(2031, 10, 15)
            )

            travel_to(job_run_date) do
              perform_enqueued_jobs { described_class.perform_now }
            end

            amendment.reload

            aggregate_failures do
              expect(amendment).to have_attributes(
                claim_changes: amendment_changes,
                personal_data_removed_at: nil
              )
            end
          end
        end

        context "when the claim is awaiting a decision" do
          it "retains personal data in the amendment" do
            amendment = create(:amendment, claim: claim, claim_changes: amendment_changes)

            travel_to(job_run_date) do
              perform_enqueued_jobs { described_class.perform_now }
            end

            amendment.reload

            aggregate_failures do
              expect(amendment).to have_attributes(
                claim_changes: amendment_changes,
                personal_data_removed_at: nil
              )
            end
          end
        end
      end
    end
  end
end
