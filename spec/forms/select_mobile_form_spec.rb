require "rails_helper"

RSpec.describe SelectMobileForm do
  shared_examples "select_mobile_form" do |journey|
    let(:claims) do
      journey::POLICIES.map { |policy| create(:claim, policy: policy) }
    end

    let(:current_claim) { CurrentClaim.new(claims: claims) }

    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers",
          :with_personal_details,
          teacher_id_user_info: {
            phone_number: "07123456789"
          }
        )
      )
    end

    let(:params) do
      ActionController::Parameters.new(claim: {mobile_check: mobile_check})
    end

    let(:form) do
      described_class.new(
        journey: journey,
        journey_session: journey_session,
        claim: current_claim,
        params: params
      )
    end

    describe "validations" do
      subject { form }

      describe "#mobile_check" do
        context "when 'use'" do
          let(:mobile_check) { "use" }

          it { is_expected.to be_valid }
        end

        context "when 'alternative'" do
          let(:mobile_check) { "alternative" }

          it { is_expected.to be_valid }
        end

        context "when 'declined'" do
          let(:mobile_check) { "declined" }

          it { is_expected.to be_valid }
        end

        context "when 'nil'" do
          let(:mobile_check) { nil }

          it { is_expected.not_to be_valid }
        end
      end
    end

    describe "#save" do
      before { form.save }

      context "when valid" do
        context "when 'use'" do
          let(:mobile_check) { "use" }

          it "updates the claims" do
            claims.each do |claim|
              expect(claim.mobile_number).to eq("07123456789")
              expect(claim.provide_mobile_number).to eq(true)
              expect(claim.mobile_check).to eq("use")
              expect(claim.mobile_verified).to eq(nil)
            end
          end
        end

        context "when 'alternative'" do
          let(:mobile_check) { "alternative" }

          it "updates the claims" do
            claims.each do |claim|
              expect(claim.mobile_number).to eq(nil)
              expect(claim.provide_mobile_number).to eq(true)
              expect(claim.mobile_check).to eq("alternative")
              expect(claim.mobile_verified).to eq(nil)
            end
          end
        end

        context "when 'declined'" do
          let(:mobile_check) { "declined" }

          it "updates the claimms" do
            claims.each do |claim|
              expect(claim.mobile_number).to eq(nil)
              expect(claim.provide_mobile_number).to eq(false)
              expect(claim.mobile_check).to eq("declined")
              expect(claim.mobile_verified).to eq(nil)
            end
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "select_mobile_form",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples(
      "select_mobile_form",
      Journeys::AdditionalPaymentsForTeaching
    )
  end
end
