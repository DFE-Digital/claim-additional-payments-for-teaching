require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::MatchingClaims do
  describe "#perform" do
    it "does not add a task when the claim has no matches" do
      claim = create_claim(email_address: "source@example.com")

      described_class.new(claim: claim).perform

      expect(claim.tasks.matching_details).to be_empty
    end

    it "adds an incomplete matching details task to both claims for a new match" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details.sole).not_to be_completed
      expect(other_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "does not add another task when a claim already has an incomplete task" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      source_task = create_incomplete_matching_details_task(source_claim)
      other_task = create_incomplete_matching_details_task(other_claim)

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(source_task)
      expect(other_claim.tasks.matching_details).to contain_exactly(other_task)
    end

    it "does not change a completed task when a new match is found" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      completed_task = create(
        :task,
        :passed,
        claim: other_claim,
        name: "matching_details"
      )

      described_class.new(claim: source_claim).perform

      expect(other_claim.tasks.matching_details).to contain_exactly(completed_task)
      expect(source_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "does not add a task to a decided claim when a new match is found" do
      decided_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      create(:decision, claim: decided_claim, approved: true)
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )

      described_class.new(claim: source_claim).perform

      expect(decided_claim.tasks.matching_details).to be_empty
      expect(source_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "does not change the source claim's completed task when a new match is found" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      completed_task = create(
        :task,
        :failed,
        claim: source_claim,
        name: "matching_details"
      )

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(completed_task)
      expect(other_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "does not add a task to the source claim when it has been decided" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      create(:decision, claim: source_claim, approved: true)

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to be_empty
      expect(other_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "does not change tasks when the set of matching claims has not changed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      source_task = create_incomplete_matching_details_task(source_claim)
      other_task = create_incomplete_matching_details_task(other_claim)

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(source_task)
      expect(other_claim.tasks.matching_details).to contain_exactly(other_task)
    end

    it "adds missing tasks when a persisted match has not changed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details.sole).not_to be_completed
      expect(other_claim.tasks.matching_details.sole).not_to be_completed
    end

    it "rolls back match changes when persisting a task fails" do
      create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      invalid_task = Task.new
      invalid_task.errors.add(:base, "task could not be saved")
      error = ActiveRecord::RecordInvalid.new(invalid_task)
      allow_any_instance_of(Task).to receive(:save!).and_raise(error)

      expect {
        described_class.new(claim: source_claim).perform
      }.to raise_error(error)

      expect(Claims::Match.matching_claims(source_claim)).to be_empty
    end

    it "removes incomplete tasks from both claims when their only match is removed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      create_incomplete_matching_details_task(source_claim)
      create_incomplete_matching_details_task(other_claim)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to be_empty
      expect(other_claim.tasks.matching_details).to be_empty
    end

    it "does not remove a completed task when a match is removed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      create_incomplete_matching_details_task(source_claim)
      completed_task = create(
        :task,
        :passed,
        claim: other_claim,
        name: "matching_details"
      )
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to be_empty
      expect(other_claim.tasks.matching_details).to contain_exactly(completed_task)
    end

    it "does not remove the source claim's completed task when a match is removed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      completed_task = create(
        :task,
        :failed,
        claim: source_claim,
        name: "matching_details"
      )
      create_incomplete_matching_details_task(other_claim)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(completed_task)
      expect(other_claim.tasks.matching_details).to be_empty
    end

    it "does not remove a task from a decided claim when a match is removed" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      create_incomplete_matching_details_task(source_claim)
      other_task = create_incomplete_matching_details_task(other_claim)
      create(:decision, claim: other_claim, approved: true)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to be_empty
      expect(other_claim.tasks.matching_details).to contain_exactly(other_task)
    end

    it "does not remove the source claim's task when it has been decided" do
      other_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 2.days.ago
      )
      source_claim = create_claim(
        email_address: "duplicate@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      source_task = create_incomplete_matching_details_task(source_claim)
      create_incomplete_matching_details_task(other_claim)
      create(:decision, claim: source_claim, approved: true)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(source_task)
      expect(other_claim.tasks.matching_details).to be_empty
    end

    it "keeps the other claim's task when it still has another match" do
      source_claim = create_claim(
        email_address: "source-and-other@example.com",
        national_insurance_number: "AB000001C",
        created_at: 3.days.ago
      )
      other_claim = create_claim(
        email_address: "source-and-other@example.com",
        national_insurance_number: "AB000002C",
        created_at: 2.days.ago
      )
      remaining_match = create_claim(
        email_address: "remaining@example.com",
        national_insurance_number: "AB000002C",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, other_claim)
      Claims::Match.create_match!(other_claim, remaining_match)
      create_incomplete_matching_details_task(source_claim)
      other_task = create_incomplete_matching_details_task(other_claim)
      create_incomplete_matching_details_task(remaining_match)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to be_empty
      expect(other_claim.tasks.matching_details).to contain_exactly(other_task)
      expect(remaining_match.tasks.matching_details.sole).not_to be_completed
    end

    it "keeps the source claim's task when it still has another match" do
      source_claim = create_claim(
        email_address: "removed@example.com",
        national_insurance_number: "AB000001C",
        created_at: 3.days.ago
      )
      removed_match = create_claim(
        email_address: "removed@example.com",
        national_insurance_number: "AB000002C",
        created_at: 2.days.ago
      )
      remaining_match = create_claim(
        email_address: "remaining@example.com",
        national_insurance_number: "AB000001C",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, removed_match)
      Claims::Match.create_match!(source_claim, remaining_match)
      source_task = create_incomplete_matching_details_task(source_claim)
      create_incomplete_matching_details_task(removed_match)
      remaining_task = create_incomplete_matching_details_task(remaining_match)
      source_claim.update!(email_address: "changed@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(source_task)
      expect(removed_match.tasks.matching_details).to be_empty
      expect(remaining_match.tasks.matching_details).to contain_exactly(remaining_task)
    end

    it "handles a removed match and a new match in the same check" do
      source_claim = create_claim(
        email_address: "old@example.com",
        created_at: 3.days.ago
      )
      removed_match = create_claim(
        email_address: "old@example.com",
        created_at: 2.days.ago
      )
      new_match = create_claim(
        email_address: "new@example.com",
        created_at: 1.day.ago
      )
      Claims::Match.create_match!(source_claim, removed_match)
      source_task = create_incomplete_matching_details_task(source_claim)
      create_incomplete_matching_details_task(removed_match)
      source_claim.update!(email_address: "new@example.com")

      described_class.new(claim: source_claim).perform

      expect(source_claim.tasks.matching_details).to contain_exactly(source_task)
      expect(removed_match.tasks.matching_details).to be_empty
      expect(new_match.tasks.matching_details.sole).not_to be_completed
    end
  end

  def create_claim(email_address:, created_at: Time.current, national_insurance_number: nil)
    attributes = {
      email_address: email_address,
      created_at: created_at,
      academic_year: AcademicYear.current
    }
    attributes[:national_insurance_number] = national_insurance_number if national_insurance_number

    create(:claim, :submitted, **attributes)
  end

  def create_incomplete_matching_details_task(claim)
    task = claim.tasks.matching_details.new(name: "matching_details")
    task.save!(context: :claim_verifier)
    task
  end
end
