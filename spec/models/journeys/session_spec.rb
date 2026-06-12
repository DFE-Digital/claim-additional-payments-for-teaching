require "rails_helper"

RSpec.shared_examples_for "a journey session" do |journey|
  let(:factory_name) { :"#{journey.i18n_namespace}_session" }
  let(:policy) { journey.policies.first }

  describe "validations" do
    describe "journey" do
      it { is_expected.to validate_presence_of(:journey) }

      it do
        is_expected.to(
          validate_inclusion_of(:journey).in_array(Journeys.all_routing_names)
        )
      end
    end
  end

  describe "#answers" do
    describe "updating answers" do
      let(:session) do
        create(
          factory_name,
          answers: {
            first_name: "Homer",
            surname: "Simpson",
            address_line_1: "742",
            address_line_2: "Evergreen Terrace",
            address_line_3: "Springfield"
          }
        )
      end

      it "allows updating an attribute without resetting other attributes " do
        session.answers.first_name = "Bart"

        session.save!

        session.reload

        expect(session.answers.first_name).to eq("Bart")
        expect(session.answers.surname).to eq("Simpson")
        expect(session.answers.address_line_1).to eq("742")
        expect(session.answers.address_line_2).to eq("Evergreen Terrace")
      end

      it "allows updating multiple attributes without resetting other attributes" do
        session.answers.assign_attributes(
          surname: "Thompson",
          address_line_2: "Terror Lake"
        )

        session.save!

        session.reload

        expect(session.answers.first_name).to eq("Homer")
        expect(session.answers.surname).to eq("Thompson")
        expect(session.answers.address_line_1).to eq("742")
        expect(session.answers.address_line_2).to eq("Terror Lake")
      end
    end
  end

  describe "when a linked claim is destroyed" do
    let(:session) { create(factory_name) }
    let!(:claim) { create(:claim, :submitted, policy: policy, journey_session: session) }

    it "keeps the session and nullifies the claim association" do
      claim.destroy!

      aggregate_failures do
        expect(described_class.where(id: session.id)).to exist
        expect(session.reload.claim).to be_nil
        expect(session).not_to be_submitted
      end
    end
  end
end

RSpec.describe Journeys::TargetedRetentionIncentivePayments::Session, type: :model do
  it_behaves_like "a journey session", Journeys::TargetedRetentionIncentivePayments
end

RSpec.describe Journeys::TeacherStudentLoanReimbursement::Session, type: :model do
  it_behaves_like "a journey session", Journeys::TeacherStudentLoanReimbursement
end
