class RemoveNotesJob < ApplicationJob
  def perform
    range = Date.new(2026, 3, 2).beginning_of_day..Date.new(2026, 3, 2).end_of_day

    Task.where(name: "census_subjects_taught", created_at: range).destroy_all
  end
end
