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

      expect(TestCronJob.send(:scheduled_job).cron).to eq(TestCronJob.cron_expression)
    end

    context "when the job is not configured to perform on schedule and an unscheduled run of the job exists" do
      before :each do
        TestCronJob.perform_later
      end

      it "leaves the job enqueued" do
        existing_job = TestCronJob.send(:enqueued_job)

        TestCronJob.schedule

        expect(TestCronJob.send(:enqueued_job)).to eq(existing_job)
      end

      it "doesn't enqueue another instance of the job" do
        expect { TestCronJob.schedule }.not_to(change { TestCronJob.send(:jobs).where(cron: nil).count })
      end

      it "schedules the job" do
        expect { TestCronJob.schedule }.to change { TestCronJob.send(:jobs).count }.by(1)
      end
    end

    context "when the job is configured to perform on schedule" do
      it "enqueues the job" do
        expect { TestWithPerformOnScheduleCronJob.schedule }.to change { TestWithPerformOnScheduleCronJob.send(:jobs).where(cron: nil).count }.by(1)
      end
    end

    context "when the job is configured to perform on schedule and an unscheduled run of the job exists" do
      before :each do
        TestWithPerformOnScheduleCronJob.perform_later
      end

      it "leaves the job enqueued" do
        existing_job = TestWithPerformOnScheduleCronJob.send(:enqueued_job)

        TestWithPerformOnScheduleCronJob.schedule

        expect(TestWithPerformOnScheduleCronJob.send(:enqueued_job)).to eq(existing_job)
      end

      it "doesn't enqueue another instance of the job" do
        expect { TestWithPerformOnScheduleCronJob.schedule }.not_to(change { TestWithPerformOnScheduleCronJob.send(:jobs).where(cron: nil).count })
      end

      it "schedules the job" do
        expect { TestWithPerformOnScheduleCronJob.schedule }.to change { TestWithPerformOnScheduleCronJob.send(:jobs).count }.by(1)
      end
    end

    context "when job was previously scheduled with the same cron expression" do
      before :each do
        TestCronJob.schedule
      end

      it "leaves the existing scheduled job unchanged" do
        existing_job = TestCronJob.send(:scheduled_job)

        TestCronJob.schedule

        expect(TestCronJob.send(:scheduled_job)).to eq(existing_job)
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
        existing_job = TestCronJob.send(:scheduled_job)

        allow(TestCronJob).to receive(:cron_expression) { "* 1 * * *" }

        expect { TestCronJob.schedule }.not_to(change { TestCronJob.send(:jobs).count })

        new_job = TestCronJob.send(:scheduled_job)

        expect(new_job).not_to eq(existing_job)
        expect(new_job.cron).to eq("* 1 * * *")
      end
    end
  end
end
