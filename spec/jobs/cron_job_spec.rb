require "rails_helper"

RSpec.describe "CronJob" do
  def queue_adapter_for_test
    DelayedJobTestAdapter.new
  end

  describe ".schedule" do
    it "schedules the job" do
      expect { TestCronJob.schedule }.to change { TestCronJob.send(:jobs).count }.by(1)
    end

    it "schedules the job with the cron expression" do
      TestCronJob.schedule

      expect(TestCronJob.send(:delayed_job).cron).to eq(TestCronJob.cron_expression)
    end

    context "when job was previously scheduled with the same cron expression" do
      before :each do
        TestCronJob.schedule
      end

      it "leaves the existing scheduled job unchanged" do
        existing_job = TestCronJob.send(:delayed_job)

        TestCronJob.schedule

        expect(TestCronJob.send(:delayed_job)).to eq(existing_job)
      end

      it "doesn't create a second scheduled job" do
        expect { TestCronJob.schedule }.not_to(change { TestCronJob.send(:jobs).count })
      end
    end

    context "when job was previously scheduled with a different cron expression" do
      before :each do
        TestCronJob.schedule
      end

      it "replaces the scheduled job with one with the new cron expression" do
        existing_job = TestCronJob.send(:delayed_job)

        allow(TestCronJob).to receive(:cron_expression) { "* 1 * * *" }

        expect { TestCronJob.schedule }.not_to(change { TestCronJob.send(:jobs).count })

        new_job = TestCronJob.send(:delayed_job)

        expect(new_job).not_to eq(existing_job)
        expect(new_job.cron).to eq("* 1 * * *")
      end
    end
  end
end
