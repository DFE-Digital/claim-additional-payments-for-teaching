require "rails_helper"

RSpec.describe TeacherDetailForm do
  let(:ecp_claim) do
    create(
      :claim,
      :with_details_from_dfe_identity,
      policy: Policies::EarlyCareerPayments,
      teacher_id_user_info: teacher_id_user_info
    )
  end

  let(:lup_claim) do
    create(
      :claim,
      :with_details_from_dfe_identity,
      policy: Policies::LevellingUpPremiumPayments,
      teacher_id_user_info: teacher_id_user_info
    )
  end

  let(:current_claim) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:form) do
    described_class.new(journey: journey, claim: current_claim, params: params)
  end

  describe "validations" do
    let(:teacher_id_user_info) { {} }
    let(:params) { ActionController::Parameters.new }

    subject { form }

    describe "details_check" do
      context "when `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              details_check: true
            }
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              details_check: false
            }
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `nil`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              details_check: nil
            }
          )
        end

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#given_name" do
    let(:params) { ActionController::Parameters.new }
    let(:teacher_id_user_info) { {"given_name" => "Seymour"} }

    subject { form.given_name }

    it { is_expected.to eq("Seymour") }
  end

  describe "#family_name" do
    let(:params) { ActionController::Parameters.new }
    let(:teacher_id_user_info) { {"family_name" => "Skinner"} }

    subject { form.family_name }

    it { is_expected.to eq("Skinner") }
  end

  describe "#birthdate" do
    let(:params) { ActionController::Parameters.new }
    subject { form.birthdate }

    context "when valid" do
      let(:teacher_id_user_info) { {"birthdate" => "1953-12-23"} }

      it { is_expected.to eq(Date.new(1953, 12, 23)) }
    end

    context "when invalid" do
      let(:teacher_id_user_info) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe "#trn" do
    let(:params) { ActionController::Parameters.new }
    let(:teacher_id_user_info) { {"trn" => "1234567"} }

    subject { form.trn }
  end

  describe "#national_insurance_number" do
    let(:params) { ActionController::Parameters.new }
    let(:teacher_id_user_info) { {"ni_number" => "QQ123456C"} }

    subject { form.national_insurance_number }
  end

  describe "#save" do
    before do
      allow(Dqt::RetrieveClaimQualificationsData).to receive(:call)
      form.save
    end

    context "when valid" do
      context "when details check is false" do
        let(:teacher_id_user_info) { {} }
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              details_check: false
            }
          )
        end

        it "resets the claim's attributes from teacher id" do
          expect(ecp_claim.first_name).to be_blank
          expect(ecp_claim.surname).to be_blank
          expect(ecp_claim.teacher_reference_number).to be_blank
          expect(ecp_claim.date_of_birth).to be_blank
          expect(ecp_claim.national_insurance_number).to be_blank

          expect(lup_claim.first_name).to be_blank
          expect(lup_claim.surname).to be_blank
          expect(lup_claim.teacher_reference_number).to be_blank
          expect(lup_claim.date_of_birth).to be_blank
          expect(lup_claim.national_insurance_number).to be_blank
        end

        it "sets logged in with tid to false" do
          expect(ecp_claim.logged_in_with_tid).to eq(false)

          expect(lup_claim.logged_in_with_tid).to eq(false)
        end

        it "sets details check to false" do
          expect(ecp_claim.details_check).to eq(false)

          expect(lup_claim.details_check).to eq(false)
        end

        it "doesn't retreive the claim's qualifications data" do
          expect(Dqt::RetrieveClaimQualificationsData).not_to(
            have_received(:call)
          )
        end
      end

      context "when details check is true" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              details_check: true
            }
          )
        end

        context "when the data back from dfe identity is not valid" do
          let(:teacher_id_user_info) do
            {
              "given_name" => "Seymour",
              "family_name" => "Skinner",
              "trn" => "1234567",
              "birthdate" => "1953-12-23",
              "ni_number" => "QQ123456C",
              "trn_match_ni_number" => "invalid"
            }
          end

          # Should we instead reset the details?
          it "doesn't update the claim's attributes from teacher id" do
            # Details set in factory
            expect(ecp_claim.first_name).to eq("Jo")
            expect(ecp_claim.surname).to eq("Bloggs")
            expect(ecp_claim.date_of_birth).to eq(20.years.ago.to_date)

            expect(lup_claim.first_name).to eq("Jo")
            expect(lup_claim.surname).to eq("Bloggs")
            expect(ecp_claim.date_of_birth).to eq(20.years.ago.to_date)
          end

          it "sets logged in with tid to true" do
            expect(ecp_claim.logged_in_with_tid).to eq(true)

            expect(lup_claim.logged_in_with_tid).to eq(true)
          end

          it "sets details check to false" do
            expect(ecp_claim.details_check).to eq(false)

            expect(lup_claim.details_check).to eq(false)
          end

          it "doesn't retreive the claim's qualifications data" do
            expect(Dqt::RetrieveClaimQualificationsData).not_to(
              have_received(:call)
            )
          end
        end

        context "when the data back from dfe identity is valid" do
          let(:teacher_id_user_info) do
            {
              "given_name" => "Seymour",
              "family_name" => "Skinner",
              "trn" => "1234567",
              "birthdate" => "1953-12-23",
              "ni_number" => "QQ123456C",
              "trn_match_ni_number" => "true"
            }
          end

          it "updates the claim's attributes from teacher id" do
            expect(ecp_claim.first_name).to eq("Seymour")
            expect(ecp_claim.surname).to eq("Skinner")
            expect(ecp_claim.teacher_reference_number).to eq("1234567")
            expect(ecp_claim.date_of_birth).to eq(Date.new(1953, 12, 23))
            expect(ecp_claim.national_insurance_number).to eq("QQ123456C")

            expect(lup_claim.first_name).to eq("Seymour")
            expect(lup_claim.surname).to eq("Skinner")
            expect(lup_claim.teacher_reference_number).to eq("1234567")
            expect(lup_claim.date_of_birth).to eq(Date.new(1953, 12, 23))
            expect(lup_claim.national_insurance_number).to eq("QQ123456C")
          end

          it "sets logged in with tid to true" do
            expect(ecp_claim.logged_in_with_tid).to eq(true)

            expect(lup_claim.logged_in_with_tid).to eq(true)
          end

          it "sets details check to true" do
            expect(ecp_claim.details_check).to eq(true)

            expect(lup_claim.details_check).to eq(true)
          end

          it "retrieves the claim's qualifications data" do
            expect(Dqt::RetrieveClaimQualificationsData).to(
              have_received(:call).with(current_claim)
            )
          end
        end
      end
    end
  end
end
