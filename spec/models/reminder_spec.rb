require "rails_helper"

RSpec.describe Reminder, type: :model do
  describe ".to_be_sent" do
    let(:count) { [*1..5].sample }
    let(:email_sent_at) { nil }
    let(:verified) { false }
    let(:itt_academic_year) { AcademicYear.current }

    before do
      create_list(
        :reminder,
        count,
        email_verified: verified,
        email_sent_at: email_sent_at,
        itt_academic_year: itt_academic_year,
        journey_class: Journeys.all.sample.to_s
      )
    end

    context "that are un-verified, not yet sent" do
      it "returns 0" do
        expect(Reminder.to_be_sent.count).to eq(0)
      end
    end

    context "that are verified, not yet sent" do
      let(:verified) { true }
      it "returns correct count" do
        expect(Reminder.to_be_sent.count).to eq(count)
      end
    end

    context "that are verified, sent" do
      let(:verified) { true }
      let(:email_sent_at) { Time.now }
      it "returns 0" do
        expect(Reminder.to_be_sent.count).to eq(0)
      end
    end

    context "that are verified but not ready to be sent" do
      let(:verified) { true }
      let(:itt_academic_year) { AcademicYear.next }
      it "returns 0" do
        expect(Reminder.to_be_sent.count).to eq(0)
      end
    end
  end
end
