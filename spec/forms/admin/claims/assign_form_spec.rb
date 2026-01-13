require "rails_helper"

RSpec.describe Admin::Claims::AssignForm do
  let!(:current_admin) { create(:dfe_signin_user, :service_operator, :with_random_name) }
  let!(:second_admin) { create(:dfe_signin_user, :service_operator, :with_random_name) }
  let!(:third_admin) { create(:dfe_signin_user, :service_operator, :with_random_name) }

  let(:claim) do
    create(
      :claim,
      assigned_to: third_admin
    )
  end

  subject do
    described_class.new(current_admin:, claim:)
  end

  describe "validations" do
    it "is not valid when no assigment is chosen" do
      expect(subject).to be_invalid
    end

    context "when assign to colleague but no colleague selected" do
      subject do
        described_class.new(
          current_admin:,
          claim:,
          assign: "colleague",
          colleague_id: nil
        )
      end

      it "is not valid" do
        expect(subject).to be_invalid
      end
    end
  end

  describe "#colleagues" do
    it "returns other service operators" do
      expect(subject.colleagues).not_to include current_admin
      expect(subject.colleagues).to include second_admin
    end

    it "excludes currently assigned admin" do
      expect(subject.colleagues).not_to include third_admin
    end
  end

  describe "#save" do
    context "when unassigning" do
      subject do
        described_class.new(current_admin:, claim:, assign: "unassign")
      end

      it "creates relevant note" do
        expect { subject.save }.to change(Note, :count).by(1)

        note = Note.last

        expect(note.claim).to eql(claim)
        expect(note.created_by).to eql(current_admin)
        expect(note.body).to eql("This claim was unassigned from #{third_admin.full_name}")
      end
    end

    context "when assigning to self" do
      subject do
        described_class.new(current_admin:, claim:, assign: "myself")
      end

      it "creates relevant note" do
        expect { subject.save }.to change(Note, :count).by(1)

        note = Note.last

        expect(note.claim).to eql(claim)
        expect(note.created_by).to eql(current_admin)
        expect(note.body).to eql("This claim was assigned to #{current_admin.full_name}")
      end
    end

    context "when assigning to colleague" do
      subject do
        described_class.new(current_admin:, claim:, assign: "colleague", colleague_id: second_admin.id)
      end

      it "creates relevant note" do
        expect { subject.save }.to change(Note, :count).by(1)

        note = Note.last

        expect(note.claim).to eql(claim)
        expect(note.created_by).to eql(current_admin)
        expect(note.body).to eql("This claim was assigned to #{second_admin.full_name}")
      end
    end
  end
end
