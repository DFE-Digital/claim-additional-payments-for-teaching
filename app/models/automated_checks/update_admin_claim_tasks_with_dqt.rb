module AutomatedChecks
  class UpdateAdminClaimTasksWithDqt
    def initialize(
      claim:,
      dqt_teacher_status:,
      admin_user: nil
    )
      self.admin_user = admin_user
      self.claim = claim
      self.qualified_teaching_status = dqt_teacher_status

      @completed_tasks = 0
    end

    def perform
      perform_qualification_check
      perform_identity_confirmation

      @completed_tasks
    end

    private

    attr_accessor :admin_user, :claim, :qualified_teaching_status

    def awaiting_task?(task_name)
      claim.tasks.none? { |task| task.name == task_name }
    end

    def identity_matches?
      qualified_teaching_status.fetch(:date_of_birth) == claim.date_of_birth && qualified_teaching_status.fetch(:surname)&.casecmp?(claim.surname)
    end

    def perform_qualification_check
      if awaiting_task?("qualifications") && claim.policy::DqtRecord.new(qualified_teaching_status).eligible?
        claim.tasks.create!(task_attributes("qualifications"))
        @completed_tasks += 1
      end
    end

    def perform_identity_confirmation
      if claim.identity_verified? && awaiting_task?("identity_confirmation") && identity_matches?
        claim.tasks.create!(task_attributes("identity_confirmation"))
        @completed_tasks += 1
      end
    end

    def task_attributes(task_name)
      {
        name: task_name,
        passed: true,
        manual: false,
        created_by: admin_user
      }
    end
  end
end
