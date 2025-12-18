module Admin
  class TaskListForm
    class ClaimPresenter
      class Task
        attr_reader :name, :status, :colour

        def initialize(name, status, colour)
          @name = name
          @status = status.downcase
          @colour = colour
        end

        def display_status
          if status == "na"
            "N/A"
          else
            status.humanize
          end
        end

        def filter_status
          if status == "no data"
            "incomplete"
          else
            status
          end
        end
      end

      attr_reader :claim, :available_tasks

      def initialize(claim:, available_tasks:)
        @claim = claim
        @available_tasks = available_tasks
      end

      def id
        @claim.id
      end

      def reference
        @claim.reference
      end

      def tasks
        @tasks ||= available_tasks.map do |task_name|
          if claim_tasks.include?(task_name)
            status, colour = ::Tasks.status(claim: claim, task_name: task_name)
            Task.new(task_name, status, colour)
          else
            Task.new(task_name, "na", "blue")
          end
        end
      end

      def task(task_name)
        tasks.find { |task| task.name == task_name }
      end

      private

      def claim_tasks
        @claim_tasks ||= claim.policy::ClaimCheckingTasks.new(
          claim,
          skip_matching_claims_check: true
        ).applicable_task_names
      end
    end

    TASKS = {
      Policies::EarlyYearsPayments => %w[
        ey_eoi_cross_reference
        one_login_identity
        ey_alternative_verification
        employment
        student_loan_plan
        payroll_details
        payroll_gender
        matching_details
      ],
      Policies::FurtherEducationPayments => %w[
        one_login_identity
        fe_alternative_verification
        fe_repeat_applicant_check
        fe_provider_verification_v2
        provider_details
        employment
        student_loan_plan
        payroll_details
        matching_details
        payroll_gender
      ],
      Policies::InternationalRelocationPayments => %w[
        first_year_application
        previous_payment
        visa
        arrival_date
        previous_residency
        employment
        teaching_hours
        employment_history
        continuous_employment
        payroll_details
        matching_details
        payroll_gender
      ],
      Policies::TargetedRetentionIncentivePayments => %w[
        identity_confirmation
        qualifications
        census_subjects_taught
        employment
        student_loan_plan
        payroll_details
        matching_details
        payroll_gender
      ],
      Policies::StudentLoans => %w[
        identity_confirmation
        qualifications
        census_subjects_taught
        employment
        student_loan_plan
        payroll_details
        matching_details
        payroll_gender
      ]
    }

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :policy_name, :string, default: "early_years_payments"
    attribute :show_filter_controls, :boolean, default: false
    attribute :statuses, default: {}
    attribute :clear_statuses, :boolean, default: false

    def initialize(params)
      super

      # Set default for initial page load
      self.statuses = all_statuses if statuses.empty? && !clear_statuses
    end

    def policy
      @policy ||= Policies.all.find { |p| p.locale_key == policy_name }
    end

    def show_filter_controls?
      show_filter_controls
    end

    def task_names
      policy_tasks.map { |task_name| I18n.t("admin.tasks.#{task_name}.name") }
    end

    def claims
      claim_scope.map do |claim|
        ClaimPresenter.new(claim: claim, available_tasks: policy_tasks)
      end.select do |presenter|
        statuses.any? do |task_name, statuses|
          statuses.include?(presenter.task(task_name).filter_status)
        end
      end
    end

    def policy_tasks
      TASKS.fetch(policy).excluding("matching_details")
    end

    def selected_statuses_for(task_key)
      statuses.fetch(task_key.to_s, []).compact_blank
    end

    def task_statuses(task_key)
      %w[passed failed incomplete]
    end

    def applied_params
      {
        policy_name: policy_name,
        statuses: statuses,
        show_filter_controls: show_filter_controls?
      }
    end

    def all_statuses
      policy_tasks.to_h { |task_name| [task_name, task_statuses(task_name)] }
    end

    private

    attr_reader :params

    def claim_scope
      Claim
        .by_academic_year(AcademicYear.current)
        .awaiting_decision
        .by_policy(policy)
        .includes(:tasks, :eligibility)
    end
  end
end
