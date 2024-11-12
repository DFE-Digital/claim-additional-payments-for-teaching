require "rails_helper"

RSpec.describe EarlyYearsProgressEmailsJob do
  let(:policy) { Policies::EarlyYearsPayments }

  describe "#perform" do
    context "when no claims" do
      it "does not enqueue any jobs" do
        expect { subject.perform }.not_to have_enqueued_job
      end
    end

    context "when normal day of the month" do
      it "enqueues jobs normally" do
        travel_to(Date.new(2024, 11, 12)) do
          create(:claim, :submitted, policy:, submitted_at: 2.months.ago - 1.day)
          claim_2 = create(:claim, :submitted, policy:, submitted_at: 2.months.ago)
          create(:claim, :submitted, policy:, submitted_at: 2.months.ago + 1.day)

          create(:claim, :submitted, policy:, submitted_at: 5.months.ago - 1.day)
          claim_5 = create(:claim, :submitted, policy:, submitted_at: 5.months.ago)
          create(:claim, :submitted, policy:, submitted_at: 5.months.ago + 1.day)

          expect { subject.perform }.to have_enqueued_job.twice

          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[0].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_2)
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[1].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_5)
        end
      end
    end

    context "when current month same number of days as previous month" do
      it "enqueues jobs normally" do
        travel_to(Date.new(2024, 12, 31)) do
          create(:claim, :submitted, policy:, submitted_at: 2.months.ago - 1.day)
          claim_2 = create(:claim, :submitted, policy:, submitted_at: 2.months.ago)
          create(:claim, :submitted, policy:, submitted_at: 2.months.ago + 1.day)

          expect { subject.perform }.to have_enqueued_job.once

          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[0].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_2)
        end
      end
    end

    context "when current month has more days than previous month" do
      it "enqueues no jobs on last day" do
        claim_1 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 2, 28))
        claim_2 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 2, 29))
        claim_3 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 3, 1))

        travel_to(Date.new(2024, 4, 28)) do
          expect { subject.perform }.to have_enqueued_job.once
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[0].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_1)
        end

        travel_to(Date.new(2024, 4, 29)) do
          expect { subject.perform }.to have_enqueued_job.once
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[1].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_2)
        end

        travel_to(Date.new(2024, 4, 30)) do
          expect { subject.perform }.not_to have_enqueued_job
        end

        travel_to(Date.new(2024, 5, 1)) do
          expect { subject.perform }.to have_enqueued_job.once
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[2].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_3)
        end
      end
    end

    context "when previous month has more days than current month" do
      it "enqueues extra jobs on last day" do
        claim_1 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 7, 29))
        claim_2 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 7, 30))
        claim_3 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 7, 31))
        claim_4 = create(:claim, :submitted, policy:, submitted_at: Date.new(2024, 8, 1))

        travel_to(Date.new(2024, 9, 29)) do
          expect { subject.perform }.to have_enqueued_job.once
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[0].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_1)
        end

        travel_to(Date.new(2024, 9, 30)) do
          expect { subject.perform }.to have_enqueued_job.twice

          expect do
            claims = queue_adapter.enqueued_jobs[1..2].map do |job|
              GlobalID::Locator.locate(job.dig(:args, 3, "params", "claim", "_aj_globalid"))
            end

            expect(claims).to include(claim_2)
            expect(claims).to include(claim_3)
          end
        end

        travel_to(Date.new(2024, 10, 1)) do
          expect { subject.perform }.to have_enqueued_job.once
          expect(GlobalID::Locator.locate(queue_adapter.enqueued_jobs[3].dig(:args, 3, "params", "claim", "_aj_globalid"))).to eql(claim_4)
        end
      end
    end
  end
end
