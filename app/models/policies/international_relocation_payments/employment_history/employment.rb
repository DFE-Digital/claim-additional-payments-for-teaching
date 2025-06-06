module Policies
  module InternationalRelocationPayments
    module EmploymentHistory
      class Employment
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :id, :string
        attribute :created_by_id, :string
        attribute :created_at, :datetime
        attribute :deleted_by_id, :string
        attribute :deleted_at, :datetime
        attribute :school_id, :string
        attribute :employment_contract_of_at_least_one_year, :boolean
        attribute :employment_start_date, :date
        attribute :employment_end_date, :date
        attribute :met_minimum_teaching_hours, :boolean
        attribute :subject_employed_to_teach, :string

        def initialize(attributes = {})
          super

          self.id ||= SecureRandom.uuid
        end

        def school=(school)
          self.school_id = school.id
        end

        def school
          School.find(school_id)
        end

        def created_by=(user)
          self.created_by_id = user.id
        end

        def created_by
          DfeSignIn::User.find(created_by_id)
        end

        def deleted_by=(user)
          self.deleted_by_id = user.id
        end

        def deleted_by
          DfeSignIn::User.find(deleted_by_id) if deleted_by_id.present?
        end

        def ==(other)
          other.id == self.id
        end

        def deleted?
          deleted_at.present?
        end
      end
    end
  end
end
