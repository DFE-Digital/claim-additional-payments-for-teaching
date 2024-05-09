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
        itt_academic_year: itt_academic_year
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

  describe ".set_a_reminder?" do
    subject { Reminder.set_a_reminder?(policy_year: policy_year, itt_academic_year: itt_academic_year) }
    let(:itt_academic_year) { AcademicYear.new(year) }

    context "Claim year: 22/23" do
      let(:policy_year) { AcademicYear.new(2022) }

      # Eligible now - but falls out of 5 year window next year so don't set a reminder
      context "ITT year: 17/18" do
        let(:year) { 2017 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 18/19" do
        let(:year) { 2018 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be true }
      end
    end

    context "Claim year: 23/24" do
      let(:policy_year) { AcademicYear.new(2023) }

      # Eligible now - but falls out of 5 year window next year so don't set a reminder
      context "ITT year: 18/19" do
        let(:year) { 2018 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 22/23" do
        let(:year) { 2022 }

        specify { expect(subject).to be true }
      end
    end

    # Last policy year - no reminders to set
    context "Claim year: 24/25" do
      let(:policy_year) { AcademicYear.new(2024) }

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 22/23" do
        let(:year) { 2022 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 23/24" do
        let(:year) { 2023 }

        specify { expect(subject).to be false }
      end
    end
  end
end
