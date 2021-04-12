require "rails_helper"

def in_browser(name)
  current_session = Capybara.session_name
  Capybara.session_name = name
  yield
  Capybara.session_name = current_session
end

RSpec.feature "Admin claim tasks update with DQT API" do
  context "with eligible claim with matching data" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1990, 8, 23),
            national_insurance_number: "QQ100000C",
            reference: "AB123456",
            surname: "ELIGIBLE",
            teacher_reference_number: "1234567"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "1234567",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "1234567",
                "name": "Fred Eligible",
                "dob": "#{claim.date_of_birth}",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2017-08-23T10:54:57.199Z",
                "ittSubject1Code": "L200",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Passed"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Passed"]')
    end
  end

  context "with eligible claim with matching data and hecos code" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1991, 1, 8),
            national_insurance_number: "QQ100000C",
            reference: "ZY987654",
            surname: "Hecos",
            teacher_reference_number: "9876543"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "9876543",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "9876543",
                "name": "Dwayne Hecos",
                "dob": "#{claim.date_of_birth}",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2017-05-20T10:54:57.199Z",
                "ittSubject1Code": "100405",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Passed"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Passed"]')
    end
  end

  context "with eligible claim with non matching date of birth" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1899, 1, 1),
            national_insurance_number: "QQ100000C",
            reference: "RR123456",
            surname: "Eligible",
            teacher_reference_number: "8901231"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "8901231",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "8901231",
                "name": "Jo Eligible",
                "dob": "1970-02-11T10:54:57.199Z",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2017-06-20T10:54:57.199Z",
                "ittSubject1Code": "C800",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Incomplete"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Passed"]')
    end
  end

  context "with eligible claim with non matching surname" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1980, 4, 10),
            national_insurance_number: "QQ100000C",
            reference: "DD123456",
            surname: "Eligible",
            teacher_reference_number: "8981212"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "8981212",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "8981212",
                "name": "Sarah Different",
                "dob": "1980-04-10T10:54:57.199Z",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2017-06-20T10:54:57.199Z",
                "ittSubject1Code": "N100",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Incomplete"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Passed"]')
    end
  end

  context "with eligible claim with ineligible DQT record" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1979, 4, 21),
            national_insurance_number: "QQ100000C",
            reference: "CD123456",
            teacher_reference_number: "6758493"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "6758493",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "6758493",
                "name": "Terry Ineligible",
                "dob": "1979-04-21T10:54:57.199Z",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2000-03-12T10:54:57.199Z",
                "ittSubject1Code": "L200",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Incomplete"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Incomplete"]')
    end
  end

  context "with eligible claim with qualification task" do
    before do
      claim = nil

      in_browser(:claimant) do
        claim = start_student_loans_claim

        claim.update!(
          attributes_for(
            :claim,
            :submittable,
            date_of_birth: Date.new(1980, 10, 4),
            national_insurance_number: "QQ100000C",
            reference: "GH123456",
            tasks: [build(:task, name: "qualifications")],
            teacher_reference_number: "6060606"
          )
        )

        claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        visit claim_path(claim.policy.routing_name, "check-your-answers")
        click_on "Confirm and send"
      end

      stub_request(:get, "http://dqt.com/api/qualified-teachers/qualified-teaching-status").with(
        query: WebMock::API.hash_including(
          {
            trn: "6060606",
            niNumber: "QQ100000C"
          }
        )
      ).to_return(
        body: <<~JSON
          {
            "data": [
              {
                "trn": "6060606",
                "name": "Already automated",
                "dob": "1980-10-04T10:54:57.199Z",
                "niNumber": "QQ100000C",
                "qtsAwardDate": "2018-05-10T10:54:57.199Z",
                "ittSubject1Code": "R400",
                "ittSubject2Code": "",
                "ittSubject3Code": "",
                "activeAlert": true
              }
            ],
            "message": null
          }
        JSON
      )

      stub_geckoboard_dataset_update
      perform_enqueued_jobs
      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)
    end

    scenario "Changes identity confirmation and qualifications claim tasks to passed" do
      expect(page).to have_xpath('//h2[normalize-space(.)="1. Identity confirmation"]/..//strong[text()="Incomplete"]')
      expect(page).to have_xpath('//h2[normalize-space(.)="2. Qualifications"]/..//strong[text()="Passed"]')
    end
  end
end
