FactoryBot.define do
  factory :report do
    trait :claim_with_failed_provider_check do
      name { Reports::FailedProviderCheckClaims::NAME }
      number_of_rows { 1 }
      csv do
        [
          [
            "Claim reference",
            "Full name",
            "Claim amount",
            "Claim status",
            "Decision date",
            "Decision agent",
            "Contract of employment",
            "Teaching responsibilities",
            "First 5 years of teaching",
            "One full term",
            "Timetabled teaching hours",
            "Age range taught",
            "Subject",
            "Course",
            "2.5 hours weekly teaching",
            "Performance",
            "Disciplinary"
          ].join(","),
          [
            "AAAAAAAA",
            "1234567",
            "John Doe",
            "£100.00",
            "Approved",
            "01/01/2025",
            "Some Admin",
            "Yes",
            "Yes",
            "Yes",
            "Yes",
            "Yes",
            "Yes",
            "Yes",
            "No"
          ].join(",")
        ].join("\n")
      end
    end

    trait :claim_with_failed_qualification_status do
      name { Reports::FailedQualificationClaims::NAME }
      number_of_rows { 1 }
      csv do
        [
          [
            "Claim reference",
            "Teacher reference number",
            "Policy name",
            "Decision date",
            "Decision agent",
            "Answered qualification",
            "Answered ITT start year",
            "Answered ITT subject",
            "DQT ITT subjects",
            "DQT ITT start year",
            "DQT QTS award date",
            "DQT qualification name"
          ].join(","),
          [
            "BBBBBBBB",
            "1234567",
            "ECP",
            "01/01/2025",
            "Some Admin",
            "postgraduate_itt",
            "2021/2022",
            "mathematics",
            "mathematics",
            "02/08/2022",
            "01/10/2023",
            "Core"
          ]
        ].join("\n")
      end
    end

    trait :duplicate_approved_claims do
      name { Reports::DuplicateClaims::NAME }
      number_of_rows { 2 }
      csv do
        [
          [
            "Claim reference",
            "Teacher reference number",
            "Full name",
            "Policy name",
            "Claim amount",
            "Claim status",
            "Decision date",
            "Decision agent"
          ],
          [
            "CCCCCCCC",
            "1234567",
            "John Doe",
            "ECP",
            "£100.00",
            "Approved",
            "01/01/2025",
            "Some Admin"
          ],
          [
            "DDDDDDDD",
            "1234567",
            "John Doe",
            "ECP",
            "£100.00",
            "Approved",
            "01/01/2025",
            "Some Admin"
          ]
        ]
      end
    end
  end
end
