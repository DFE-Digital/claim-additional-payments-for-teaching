require "rails_helper"

RSpec.describe Claim::Scrubber do
  describe ".scrub!" do
    it "removes the specified attributes from the claim and its amendments" do
      claim = create(
        :claim,
        :submitted,
        first_name: "John",
        surname: "Doe",
        date_of_birth: Date.new(1980, 1, 1),
        dqt_teacher_status: {
          trn: 123456,
          ni_number: "AB123123A"
        }
      )

      amendment_1 = create(
        :amendment,
        claim: claim,
        claim_changes: {"first_name" => ["John", "Jane"]}
      )

      amendment_2 = create(
        :amendment,
        claim: claim,
        claim_changes: {"surname" => ["Doe", "Smith"]}
      )

      expect do
        described_class.scrub!(
          claim,
          %i[first_name surname date_of_birth dqt_teacher_status]
        )
      end.to(
        change { claim.reload.first_name }
        .from("John")
        .to(nil)
        .and(
          change { claim.reload.surname }
          .from("Doe")
          .to(nil)
        ).and(
          change { claim.reload.date_of_birth }
          .from(Date.new(1980, 1, 1))
          .to(nil)
        ).and(
          change { claim.reload.dqt_teacher_status }
          .from({"trn" => 123456, "ni_number" => "AB123123A"})
          .to(nil)
        ).and(
          change { amendment_1.reload.claim_changes }
          .from({"first_name" => ["John", "Jane"]})
          .to({"first_name" => nil})
        ).and(
          change { amendment_2.reload.claim_changes }
          .from({"surname" => ["Doe", "Smith"]})
          .to({"surname" => nil})
        )
      )
    end

    context "when a claim from a legacy policy eg additional-payments" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          first_name: "John",
          surname: "Doe",
          date_of_birth: Date.new(1980, 1, 1),
          dqt_teacher_status: {
            trn: 123456,
            ni_number: "AB123123A"
          }
        )
      end

      let!(:journey_session) do
        create(
          :student_loans_session,
          claim:
        )
      end

      before do
        journey_session.update_attribute(:journey, "additional-payments")
      end

      it "does not raise an error" do
        expect { described_class.scrub!(claim, []) }.not_to raise_error
      end
    end
  end
end
