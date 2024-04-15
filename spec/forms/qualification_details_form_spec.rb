require "rails_helper"

RSpec.describe QualificationDetailsForm do
  before { create(:journey_configuration, :additional_payments) }

  before { create(:journey_configuration, :student_loans) }

  let(:additional_payments_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:student_loans_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:early_career_payments_eligibility) do
    create(
      :early_career_payments_eligibility,
      itt_academic_year: AcademicYear.new(2023),
      eligible_itt_subject: :physics,
      qualification: :postgraduate_itt
    )
  end

  let(:levelling_up_premium_payments_eligibility) do
    create(
      :levelling_up_premium_payments_eligibility,
      itt_academic_year: AcademicYear.new(2023),
      eligible_itt_subject: :physics,
      qualification: :postgraduate_itt,
      eligible_degree_subject: false
    )
  end

  let(:student_loans_eligibility) do
    create(:student_loans_eligibility)
  end

  let(:early_career_payments_claim) do
    create(
      :claim,
      policy: Policies::EarlyCareerPayments,
      eligibility: early_career_payments_eligibility,
      dqt_teacher_status: dqt_teacher_status
    )
  end

  let(:levelling_up_premium_payments_claim) do
    create(
      :claim,
      policy: Policies::LevellingUpPremiumPayments,
      eligibility: levelling_up_premium_payments_eligibility,
      dqt_teacher_status: dqt_teacher_status
    )
  end

  let(:student_loans_claim) do
    create(
      :claim,
      policy: Policies::StudentLoans,
      eligibility: student_loans_eligibility,
      dqt_teacher_status: dqt_teacher_status
    )
  end

  let(:additional_payments_current_claim) do
    CurrentClaim.new(
      claims: [
        early_career_payments_claim,
        levelling_up_premium_payments_claim
      ]
    )
  end

  let(:student_loans_current_claim) do
    CurrentClaim.new(claims: [student_loans_claim])
  end

  let(:form) do
    described_class.new(
      journey: journey,
      claim: current_claim,
      params: params
    )
  end

  describe "validations" do
    let(:journey) { additional_payments_journey }

    let(:current_claim) { additional_payments_current_claim }

    let(:dqt_teacher_status) { {} }

    subject(:form_subject) { form }

    describe "qualifications_details_check" do
      context "when `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: false}
          )
        end

        it { is_expected.to be_valid }
      end

      context "when not present" do
        let(:params) { ActionController::Parameters.new(claim: {}) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#save" do
    context "when invalid" do
      let(:journey) { additional_payments_journey }

      let(:current_claim) { additional_payments_current_claim }

      let(:dqt_teacher_status) { {} }

      let(:params) { ActionController::Parameters.new(claim: {}) }

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when valid" do
      context "when on the additional payments journey" do
        let(:journey) { additional_payments_journey }

        let(:current_claim) { additional_payments_current_claim }

        context "when the qualifications_details_check is `false`" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {qualifications_details_check: false}
            )
          end

          let(:dqt_teacher_status) { {} }

          it "sets the qualifications_details_check to `false`" do
            expect { form.save }.to(
              change do
                early_career_payments_claim
                  .reload
                  .qualifications_details_check
              end.from(nil).to(false).and(
                change do
                  levelling_up_premium_payments_claim
                    .reload
                    .qualifications_details_check
                end.from(nil).to(false)
              )
            )
          end

          it "sets itt_academic_year as nil" do
            expect { form.save }.to(
              change do
                early_career_payments_eligibility.reload.itt_academic_year
              end.from(AcademicYear.new(2023)).to(nil).and(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .itt_academic_year
                end.from(AcademicYear.new(2023)).to(nil)
              )
            )
          end

          it "sets eligible_itt_subject as nil" do
            expect { form.save }.to(
              change do
                early_career_payments_eligibility
                  .reload
                  .eligible_itt_subject
              end.from("physics").to(nil).and(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .eligible_itt_subject
                end.from("physics").to(nil)
              )
            )
          end

          it "sets the qualification as nil" do
            expect { form.save }.to(
              change do
                early_career_payments_eligibility.reload.qualification
              end.from("postgraduate_itt").to(nil).and(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .qualification
                end.from("postgraduate_itt").to(nil)
              )
            )
          end

          it "sets the eligible_degree_subject as nil" do
            expect { form.save }.to(
              change do
                levelling_up_premium_payments_eligibility
                  .reload
                  .eligible_degree_subject
              end.from(false).to(nil)
            )
          end
        end

        context "when the qualifications_details_check is `true`" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {qualifications_details_check: true}
            )
          end

          context "when there is a dqt_teacher_record" do
            let(:dqt_teacher_status) do
              {
                trn: 123456,
                ni_number: "AB123123A",
                name: "Rick Sanchez",
                dob: "66-06-06T00:00:00",
                active_alert: false,
                state: 0,
                state_name: "Active",
                qualified_teacher_status: {
                  name: "Qualified teacher (trained)",
                  qts_date: "2018-12-01",
                  state: 0,
                  state_name: "Active"
                },
                induction: {
                  start_date: "2021-07-01T00:00:00Z",
                  completion_date: "2021-07-05T00:00:00Z",
                  status: "Pass",
                  state: 0,
                  state_name: "Active"
                },
                initial_teacher_training: {
                  programme_start_date: "666-06-06T00:00:00",
                  programme_end_date: "2021-07-04T00:00:00Z",
                  programme_type: "Overseas Trained Teacher Programme",
                  result: "Pass",
                  subject1: "mathematics",
                  subject1_code: "G100",
                  subject2: nil,
                  subject2_code: nil,
                  subject3: nil,
                  subject3_code: nil,
                  qualification: "BA (Hons)",
                  state: 0,
                  state_name: "Active"
                },
                qualifications: [
                  {
                    he_subject1_code: "G100"
                  }
                ]
              }
            end

            it "sets the qualifications_details_check to `true`" do
              expect { form.save }.to(
                change do
                  early_career_payments_claim
                    .reload
                    .qualifications_details_check
                end.from(nil).to(true).and(
                  change do
                    levelling_up_premium_payments_claim
                      .reload
                      .qualifications_details_check
                  end.from(nil).to(true)
                )
              )
            end

            it "sets the itt_academic_year to the dqt_teacher_record" do
              expect { form.save }.to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .itt_academic_year
                end.from(AcademicYear.new(2023)).to(AcademicYear.new(2018)).and(
                  change do
                    levelling_up_premium_payments_eligibility
                      .reload
                      .itt_academic_year
                  end.from(AcademicYear.new(2023)).to(AcademicYear.new(2018))
                )
              )
            end

            it "sets the eligible_itt_subject to the dqt_teacher_record" do
              expect { form.save }.to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .eligible_itt_subject
                end.from("physics").to("mathematics").and(
                  change do
                    levelling_up_premium_payments_eligibility
                      .reload
                      .eligible_itt_subject
                  end.from("physics").to("mathematics")
                )
              )
            end

            it "sets the qualification to the dqt_teacher_record" do
              expect { form.save }.to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .qualification
                end.from("postgraduate_itt").to("undergraduate_itt").and(
                  change do
                    levelling_up_premium_payments_eligibility
                      .reload
                      .qualification
                  end.from("postgraduate_itt").to("undergraduate_itt")
                )
              )
            end

            it "sets the eligible_degree_subject to the dqt_teacher_record" do
              expect { form.save }.to(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .eligible_degree_subject
                end.from(false).to(true)
              )
            end
          end

          context "when there is no dqt_teacher_record" do
            let(:dqt_teacher_status) { {} }

            it "sets the qualifications_details_check to `true`" do
              expect { form.save }.to(
                change do
                  early_career_payments_claim
                    .reload
                    .qualifications_details_check
                end.from(nil).to(true).and(
                  change do
                    levelling_up_premium_payments_claim
                      .reload
                      .qualifications_details_check
                  end.from(nil).to(true)
                )
              )
            end

            it "doesn't change the itt_academic_year" do
              expect { form.save }.not_to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .itt_academic_year
                end
              )

              expect { form.save }.not_to(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .itt_academic_year
                end
              )
            end

            it "doesn't change the eligible_itt_subject" do
              expect { form.save }.not_to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .eligible_itt_subject
                end
              )

              expect { form.save }.not_to(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .eligible_itt_subject
                end
              )
            end

            it "doesn't change the qualification" do
              expect { form.save }.not_to(
                change do
                  early_career_payments_eligibility
                    .reload
                    .qualification
                end
              )

              expect { form.save }.not_to(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .qualification
                end
              )
            end

            it "doesn't change the eligible_degree_subject" do
              expect { form.save }.not_to(
                change do
                  levelling_up_premium_payments_eligibility
                    .reload
                    .eligible_degree_subject
                end
              )
            end
          end
        end
      end

      context "when on the student loans journey" do
        let(:journey) { student_loans_journey }

        let(:current_claim) { student_loans_current_claim }

        context "when the qualifications_details_check is `false`" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {qualifications_details_check: false}
            )
          end

          let(:dqt_teacher_status) { {} }

          it "sets the qualifications_details_check to `false`" do
            expect { form.save }.to(
              change do
                student_loans_claim
                  .reload
                  .qualifications_details_check
              end.from(nil).to(false)
            )
          end

          it "sets qts_award_year as nil" do
            form.save

            expect(student_loans_eligibility.reload.qts_award_year).to eq nil
          end
        end

        context "when the qualifications_details_check is `true`" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {qualifications_details_check: true}
            )
          end

          context "when there is a dqt_teacher_record" do
            let(:dqt_teacher_status) do
              {
                trn: 123456,
                ni_number: "AB123123A",
                name: "Rick Sanchez",
                dob: "66-06-06T00:00:00",
                active_alert: false,
                state: 0,
                state_name: "Active",
                qualified_teacher_status: {
                  name: "Qualified teacher (trained)",
                  qts_date: qts_award_date,
                  state: 0,
                  state_name: "Active"
                },
                induction: {
                  start_date: "2021-07-01T00:00:00Z",
                  completion_date: "2021-07-05T00:00:00Z",
                  status: "Pass",
                  state: 0,
                  state_name: "Active"
                },
                initial_teacher_training: {
                  programme_start_date: "666-06-06T00:00:00",
                  programme_end_date: "2021-07-04T00:00:00Z",
                  programme_type: "Overseas Trained Teacher Programme",
                  result: "Pass",
                  subject1: "mathematics",
                  subject1_code: "G100",
                  subject2: nil,
                  subject2_code: nil,
                  subject3: nil,
                  subject3_code: nil,
                  qualification: "BA (Hons)",
                  state: 0,
                  state_name: "Active"
                },
                qualifications: [
                  {
                    he_subject1_code: "G100"
                  }
                ]
              }
            end

            context "when the dqt teacher record has a qts award date" do
              context "when the qts award date is eligible" do
                let(:qts_award_date) do
                  Date.new(
                    Policies::StudentLoans.first_eligible_qts_award_year.start_year,
                    9,
                    1
                  )
                end

                it "sets the qts_award_year to :on_or_after_cut_off_date" do
                  expect { form.save }.to(
                    change do
                      student_loans_eligibility.reload.qts_award_year
                    end.from(nil).to("on_or_after_cut_off_date")
                  )
                end

                it "sets the qualifications_details_check to `true`" do
                  expect { form.save }.to(
                    change do
                      student_loans_claim.reload.qualifications_details_check
                    end.from(nil).to(true)
                  )
                end
              end

              context "when the qts award date is not eligible" do
                let(:qts_award_date) do
                  Date.new(
                    Policies::StudentLoans.first_eligible_qts_award_year.start_year,
                    1,
                    1
                  )
                end

                it "sets the qts_award_year to :before_cut_off_date" do
                  expect { form.save }.to(
                    change do
                      student_loans_eligibility
                        .reload
                        .qts_award_year
                    end.from(nil).to("before_cut_off_date")
                  )
                end

                it "sets the qualifications_details_check to `true`" do
                  expect { form.save }.to(
                    change do
                      student_loans_claim.reload.qualifications_details_check
                    end.from(nil).to(true)
                  )
                end
              end
            end

            context "when the dqt teacher record has no qts award date" do
              let(:qts_award_date) { nil }

              it "sets qts_award_year as nil" do
                form.save

                expect(
                  student_loans_eligibility.reload.qts_award_year
                ).to eq nil
              end

              it "sets the qualifications_details_check to `true`" do
                expect { form.save }.to(
                  change do
                    student_loans_claim.reload.qualifications_details_check
                  end.from(nil).to(true)
                )
              end
            end
          end

          context "when there is no dqt_teacher_record" do
            let(:dqt_teacher_status) { {} }

            it "sets qts_award_year as nil" do
              form.save

              expect(
                student_loans_eligibility.reload.qts_award_year
              ).to eq nil
            end

            it "sets the qualifications_details_check to `true`" do
              expect { form.save }.to(
                change do
                  student_loans_claim.reload.qualifications_details_check
                end.from(nil).to(true)
              )
            end
          end
        end
      end
    end
  end
end
