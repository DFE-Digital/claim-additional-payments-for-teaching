class RemoveApprovedStudentLoanEmploymentsJob < ApplicationJob
  def perform
    claims = Claim
      .includes(:tasks)
      .where(tasks: {name: "employment", passed: true})
      .where("tasks.created_at > ?", Date.new(2026, 3, 1))
      .by_academic_year(Policies::StudentLoans.current_academic_year)
      .by_policy(Policies::StudentLoans)
      .awaiting_decision

    claims.each do |claim|
      claim.tasks.where(name: "employment", passed: true).destroy_all
    end
  end
end
