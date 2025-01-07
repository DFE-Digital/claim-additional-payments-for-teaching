class DailyEntityTableCheckJob < ApplicationJob
  def perform
    DfE::Analytics::EntityTableCheckJob.new.perform
  end
end
