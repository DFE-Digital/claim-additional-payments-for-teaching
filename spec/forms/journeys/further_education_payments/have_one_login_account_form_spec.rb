require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::HaveOneLoginAccountForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:have_one_login_account) { "" }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        have_one_login_account:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    context "when no option selected" do
      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:have_one_login_account]).to eql(["Choose yes if you have a GOV.UK One Login account"])
      end
    end
  end

  describe "#save" do
    let(:have_one_login_account) { "i_dont_know" }

    it "updates journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.have_one_login_account }.to("i_dont_know")
      )
    end
  end
end
