FactoryBot.define do
  factory :form do
    given_name { "John" }
    middle_name { "M" }
    family_name { "Doe" }
    email_address { "john.doe@example.com" }
    phone_number { "1234567890" }
    date_of_birth { 30.years.ago }
    nationality { "British" }
    sex { "male" }
    passport_number { "123456789" }
    subject { "Mathematics" }
    visa_type { "Type A" }
    date_of_entry { 1.month.ago }
    start_date { 1.day.ago }
    address_line_1 { "221 Baker Street" }
    address_line_2 { "Line 2" }
    city { "London" }
    postcode { "NW1 6XE" }
    application_route { "teacher" }
    state_funded_secondary_school { true }
    one_year { false }
    school_name { "Rosewood High" }
    school_headteacher_name { "Mr. Smith" }
    school_address_line_1 { "Some Street" }
    school_address_line_2 { "Another Line" }
    school_city { "London" }
    school_postcode { "SW1A 1AA" }
    student_loan { true }

    factory :teacher_form do
      application_route { "teacher" }
    end

    factory :trainee_form do
      application_route { "salaried_trainee" }
    end
  end
end
