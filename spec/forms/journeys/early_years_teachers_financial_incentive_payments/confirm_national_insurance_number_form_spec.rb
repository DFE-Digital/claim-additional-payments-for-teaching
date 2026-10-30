require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::ConfirmNationalInsuranceNumberForm, type: :model do
  let(:journey) { Journeys::EarlyYearsTeachersFinancialIncentivePayments }
  let(:journey_session) { create(:eytfi_session, answers:) }

  let(:answers) do
    build(:eytfi_answers, trs_national_insurance_number: "AB123456C")
  end

  let(:params) do
    ActionController::Parameters.new(claim: claim_params)
  end

  let(:claim_params) { {} }

  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#trs_national_insurance_number" do
    it "returns the National Insurance number from the teaching record" do
      expect(form.trs_national_insurance_number).to eq("AB123456C")
    end
  end

  describe "validations" do
    describe "#confirm_national_insurance_number" do
      context "when nothing is selected" do
        it "is invalid" do
          expect(form).not_to be_valid

          expect(form.errors[:confirm_national_insurance_number]).to include(
            "Select yes if this is your National Insurance number"
          )
        end
      end

      context "when the claimant confirms the number" do
        let(:claim_params) { {confirm_national_insurance_number: "true"} }

        it { is_expected.to be_valid }
      end
    end

    describe "#national_insurance_number" do
      context "when the claimant confirms the number from their teaching record" do
        let(:claim_params) do
          {
            confirm_national_insurance_number: "true",
            national_insurance_number: ""
          }
        end

        it "does not require them to enter one" do
          expect(form).to be_valid
        end
      end

      context "when the claimant rejects the number from their teaching record" do
        context "and enters nothing" do
          let(:claim_params) do
            {
              confirm_national_insurance_number: "false",
              national_insurance_number: ""
            }
          end

          it "is invalid" do
            expect(form).not_to be_valid

            expect(form.errors[:national_insurance_number]).to include(
              "Enter a National Insurance number in the correct format"
            )
          end
        end

        context "and enters a badly formatted number" do
          let(:claim_params) do
            {
              confirm_national_insurance_number: "false",
              national_insurance_number: "not-a-nino"
            }
          end

          it "is invalid" do
            expect(form).not_to be_valid

            expect(form.errors[:national_insurance_number]).to include(
              "Enter a National Insurance number in the correct format"
            )
          end
        end

        context "and enters a number with a disallowed prefix" do
          let(:claim_params) do
            {
              confirm_national_insurance_number: "false",
              national_insurance_number: "QQ123456C"
            }
          end

          it "is invalid" do
            expect(form).not_to be_valid

            expect(form.errors[:national_insurance_number]).to include(
              "Enter a National Insurance number in the correct format"
            )
          end
        end

        context "and enters a valid number" do
          let(:claim_params) do
            {
              confirm_national_insurance_number: "false",
              national_insurance_number: "BB123456C"
            }
          end

          it { is_expected.to be_valid }
        end

        context "and enters a valid number in a poor format" do
          let(:claim_params) do
            {
              confirm_national_insurance_number: "false",
              national_insurance_number: "bB1 23456 c"
            }
          end

          it "normalises the number before validating it" do
            expect(form).to be_valid
            expect(form.national_insurance_number).to eq("BB123456C")
          end
        end
      end
    end
  end

  describe "#save" do
    context "when the claimant confirms the number from their teaching record" do
      let(:claim_params) { {confirm_national_insurance_number: "true"} }

      it "returns true" do
        expect(form.save).to be true
      end

      it "records the confirmation" do
        expect { form.save }.to change {
          journey_session.reload.answers.confirm_national_insurance_number
        }.from(nil).to(true)
      end

      it "copies the number from the teaching record onto the answers" do
        expect { form.save }.to change {
          journey_session.reload.answers.national_insurance_number
        }.from(nil).to("AB123456C")
      end

      it "leaves the number from the teaching record intact" do
        form.save

        expect(
          journey_session.reload.answers.trs_national_insurance_number
        ).to eq("AB123456C")
      end
    end

    context "when the claimant rejects the number from their teaching record" do
      let(:claim_params) do
        {
          confirm_national_insurance_number: "false",
          national_insurance_number: "bB1 23456 c"
        }
      end

      it "returns true" do
        expect(form.save).to be true
      end

      it "records the rejection" do
        expect { form.save }.to change {
          journey_session.reload.answers.confirm_national_insurance_number
        }.from(nil).to(false)
      end

      it "saves the normalised number the claimant entered" do
        expect { form.save }.to change {
          journey_session.reload.answers.national_insurance_number
        }.from(nil).to("BB123456C")
      end

      it "keeps the number from the teaching record so the two can be compared" do
        form.save

        expect(
          journey_session.reload.answers.trs_national_insurance_number
        ).to eq("AB123456C")
      end
    end

    context "when the form is invalid" do
      let(:claim_params) do
        {
          confirm_national_insurance_number: "false",
          national_insurance_number: "not-a-nino"
        }
      end

      it "returns false" do
        expect(form.save).to be false
      end

      it "does not persist anything to the session" do
        expect { form.save }.not_to change {
          journey_session.reload.answers.attributes
        }
      end
    end
  end
end
