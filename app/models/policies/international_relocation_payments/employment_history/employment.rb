module Policies
  module InternationalRelocationPayments
    module EmploymentHistory
      class Employment
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :school_id, :string
        attribute :employment_contract_of_at_least_one_year, :boolean
        attribute :employment_start_date, :date
        attribute :employment_end_date, :date
        attribute :met_minimum_teaching_hours, :boolean
        attribute :subject_employed_to_teach, :string

        def school=(school)
          self.school_id = school.id
        end

        def school
          School.find(school_id)
        end
      end
    end
  end
end
