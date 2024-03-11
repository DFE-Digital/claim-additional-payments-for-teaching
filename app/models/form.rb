# == Schema Information
#
# Table name: forms
#
#  id                            :bigint           not null, primary key
#  address_line_1                :string
#  address_line_2                :string
#  application_route             :string
#  city                          :string
#  date_of_birth                 :date
#  date_of_entry                 :date
#  email_address                 :string
#  family_name                   :string
#  given_name                    :string
#  middle_name                   :string
#  nationality                   :string
#  one_year                      :boolean
#  passport_number               :string
#  phone_number                  :string
#  postcode                      :string
#  school_address_line_1         :string
#  school_address_line_2         :string
#  school_city                   :string
#  school_headteacher_name       :string
#  school_name                   :string
#  school_postcode               :string
#  sex                           :string
#  start_date                    :date
#  state_funded_secondary_school :boolean
#  student_loan                  :boolean
#  subject                       :string
#  visa_type                     :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#
class Form < ApplicationRecord
  def teacher_route?
    application_route == "teacher"
  end

  def trainee_route?
    application_route == "salaried_trainee"
  end

  def eligible?
    Form::EligibilityCheck.new(self).passed?
  end

  def complete?
    Form::CompletenessCheck.new(self).passed?
  end

  def validate_eligibility
    return if Form::EligibilityCheck.new(self).passed?

    errors.add(:base, :eligibility, message: Form::EligibilityCheck.new(self).failure_reason)
  end

  def validate_completeness
    return if Form::CompletenessCheck.new(self).passed?

    errors.add(:base, :completeness, message: Form::CompletenessCheck.new(self).failure_reason)
  end

  def deconstruct_keys(_keys)
    attributes.symbolize_keys
  end
end
