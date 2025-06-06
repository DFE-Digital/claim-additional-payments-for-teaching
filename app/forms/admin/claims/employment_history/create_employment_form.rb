module Admin
  module Claims
    module EmploymentHistory
      class CreateEmploymentForm
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveRecord::AttributeAssignment
        include FormHelpers

        attr_reader :claim

        attr_accessor :created_by

        attribute :school_id, :string

        attribute :school_search, :string

        attribute :employment_contract_of_at_least_one_year, :boolean

        attribute :employment_start_date, :date

        attribute :employment_end_date, :date

        attribute :met_minimum_teaching_hours, :boolean

        attribute :subject_employed_to_teach, :string

        validates :created_by, presence: true

        validate :validate_school_selected

        validates :employment_contract_of_at_least_one_year,
          inclusion: {
            in: ->(form) { form.employment_contract_of_at_least_one_year_options.map(&:id) },
            message: "Select whether the employment contract is of at least one year"
          }

        validates :subject_employed_to_teach,
          inclusion: {
            in: ->(form) { form.subject_employed_to_teach_options.map(&:id) },
            message: "Select a subject employed to teach"
          }

        validates :met_minimum_teaching_hours,
          inclusion: {
            in: ->(form) { form.met_minimum_teaching_hours_options.map(&:id) },
            message: "Select whether the minimum teaching hours were met"
          }

        validates :employment_start_date,
          presence: {message: "Enter an employment start date"}

        validates :employment_start_date,
          comparison: {
            less_than_or_equal_to: -> { Date.yesterday },
            message: "The employment start date must be in the past"
          },
          if: :employment_start_date

        validates :employment_end_date,
          presence: {message: "Enter an employment end date"}

        validates :employment_end_date,
          comparison: {
            less_than_or_equal_to: -> { Date.yesterday },
            message: "The employment end date must be in the past"
          },
          if: :employment_end_date

        validates :employment_end_date,
          comparison: {
            greater_than: :employment_start_date,
            message: "The employment end date must be after the employment start date"
          },
          if: -> { employment_start_date.present? && employment_end_date.present? }

        def initialize(claim, params: {})
          @claim = claim

          super(params)
        end

        def employment_contract_of_at_least_one_year_options
          [
            Form::Option.new(id: true, name: "Yes"),
            Form::Option.new(id: false, name: "No")
          ]
        end

        def subject_employed_to_teach_options
          [
            Form::Option.new(id: "physics", name: "Physics"),
            Form::Option.new(
              id: "combined_with_physics",
              name: "General or combined science, including physics"
            ),
            Form::Option.new(id: "languages", name: "Languages"),
            Form::Option.new(id: "other", name: "Other")
          ]
        end

        def met_minimum_teaching_hours_options
          [
            Form::Option.new(id: true, name: "Yes"),
            Form::Option.new(id: false, name: "No")
          ]
        end

        def save
          return false unless valid?

          employment = claim.policy::EmploymentHistory::Employment.new(
            school: school,
            employment_contract_of_at_least_one_year: employment_contract_of_at_least_one_year,
            employment_start_date: employment_start_date,
            employment_end_date: employment_end_date,
            met_minimum_teaching_hours: met_minimum_teaching_hours,
            subject_employed_to_teach: subject_employed_to_teach,
            created_by: created_by,
            created_at: DateTime.now
          )

          eligibility = claim.eligibility

          history = Array.new(eligibility.employment_history) << employment

          eligibility.employment_history = history

          eligibility.save!
        end

        private

        def school
          @school ||= School.find_by(id: school_id)
        end

        def validate_school_selected
          unless school.present?
            errors.add(:school_search, "Select a school")
          end
        end

        def i18n_namespace
          "admin"
        end
      end
    end
  end
end
