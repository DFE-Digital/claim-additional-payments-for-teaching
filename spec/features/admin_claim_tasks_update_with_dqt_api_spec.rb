require "rails_helper"

RSpec.feature "Admin claim tasks update with DQT API" do
  def claimant_submits_claim(claim_attributes:)
    claim = nil

    in_browser(:claimant) do
      policy_underscored = claim_attributes[:policy].to_s.underscore
      claim = send("start_#{policy_underscored}_claim")

      claim.update!(
        attributes_for(
          :claim,
          :submittable,
          **claim_attributes
        )
      )

      claim.eligibility.update!(
        attributes_for(
          :"#{policy_underscored}_eligibility",
          :eligible
        )
      )

      visit claim_path(claim.policy.routing_name, "check-your-answers")
      claim_attributes[:policy] == EarlyCareerPayments ? click_on("Accept and send") : click_on("Confirm and send")
    end

    claim
  end

  def in_browser(name)
    current_session = Capybara.session_name
    Capybara.session_name = name
    yield
    Capybara.session_name = current_session
  end

  def banner
    page.find("div", class: ["banner"])
  end

  def notes
    page.all("div", class: ["hmcts-timeline__item"])
  end

  def task(name)
    page.find("h2", text: name).sibling("*").find("strong", class: ["app-task-list__task-completed"])
  end

  def task_outcome
    page.find("div", class: ["govuk-inset-text"])
  end

  before do
    stub_geckoboard_dataset_update
    sign_in_as_service_operator

    if data.nil?
      body = nil

      status = 404
    else
      body = {
        trn: data[:teacher_reference_number],
        ni_number: data[:national_insurance_number],
        name: data[:name],
        dob: data[:date_of_birth] || Date.today,
        active_alert: data[:active_alert?] || false,
        state: 0,
        state_name: "Active",
        qualified_teacher_status: {
            name: "Qualified teacher (trained)",
            qts_date: "#{data[:qts_award_date] || Date.today}",
            state: 0,
            state_name: "Active"
        },
        induction: {
            start_date: "2021-07-01T00:00:00Z",
            completion_date: "2021-07-05T00:00:00Z",
            status: "Pass",
            state: 0,
            state_name: "Active"
        },
        initial_teacher_training: {
            programme_start_date: "#{data[:itt_start_date] || Date.today}",
            programme_end_date: "2021-07-04T00:00:00Z",
            programme_type: "Overseas Trained Teacher Programme",
            result: "Pass",
            subject1: "#{data.dig(:itt_subject_codes, 0)}",
            subject2: "#{data.dig(:itt_subject_codes, 1)}",
            subject3: "#{data.dig(:itt_subject_codes, 2)}",
            qualification: "#{data[:qualification_name] || "BA"}",
            state: 0,
            state_name: "Active"
        }
      }

      status = 200
    end

    stub_request(:post, "#{ENV['FWY_BEARER_BASE_URL']}")
      .with(body: Faraday::FlatParamsEncoder.encode(
        {
          grant_type: ENV["FWY_BEARER_GRANT_TYPE"],
          scope: ENV["FWY_BEARER_SCOPE"],
          client_id: ENV["FWY_BEARER_CLIENT_ID"],
          client_secret: ENV["FWY_BEARER_CLIENT_SECRET"]
        }
      ))
      .to_return(
        body: { access_token: "1234" }.to_json,
        status: 200
      )

    stub_request(:get, "#{ENV['FWY_BASE_URL']}teachers/#{claim.teacher_reference_number}")
      .with(query: WebMock::API.hash_including({
        birthdate: claim.date_of_birth.to_s,
        nino: claim.national_insurance_number
      }))
      .to_return(
        body: body.to_json,
        status: status,
        headers: {"Content-Type"=> "application/json"}
      )

    perform_enqueued_jobs
  end

  context "with EarlyCareerPayments policy" do
    let(:policy) { EarlyCareerPayments }

    context "with submitted claim" do
      let(:claim) do
        claimant_submits_claim(
          claim_attributes: {
            academic_year: AcademicYear.new(2021),
            date_of_birth: Date.new(1990, 8, 23),
            first_name: "Fred",
            national_insurance_number: "QQ100000C",
            policy: policy,
            reference: "AB123456",
            surname: "ELIGIBLE",
            teacher_reference_number: "1234567"
          }
        )
      end

      context "with matching DQT identity" do
        let(:data) do
          {
            date_of_birth: claim.date_of_birth,
            name: "#{claim.first_name} #{claim.surname}",
            national_insurance_number: claim.national_insurance_number,
            teacher_reference_number: claim.teacher_reference_number
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation passed" do
            expect(task("Identity confirmation")).to have_text("Passed")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not matched by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot matched}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except national insurance number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: "QQ100000B",
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows National Insurance number not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "National Insurance number not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching teacher reference number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: "7654321"
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation incomplete" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows teacher reference number not matched by an automated check" do
              expect(notes).to include(
                have_text("Teacher reference number not matched").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching first name" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows first name or surname not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching surname" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Except",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows first name or surname not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "with middle names" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Middle Names #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Passed")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome performed by automated check" do
              expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by an automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching date of birth" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation partial match" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "with admin claims tasks identity confirmation passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: :identity_confirmation)],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :identity_confirmation).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "with teacher status alert" do
          let(:data) do
            {
              active_alert?: true,
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  within(".banner") do
                    "Teacher’s identity has an active alert. Speak to manager before checking this claim."
                  end
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end

          context "admin claim" do
            before { visit admin_claim_path(claim) }

            scenario "shows note in banner" do
              expect(banner).to have_text("Teacher’s identity has an active alert. Speak to manager before checking this claim.")
            end
          end
        end

        context "except multiple matches" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation partial match" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows multiple not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )

              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end
      end

      context "without matching DQT identity" do
        let(:data) { nil }

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation no match" do
            expect(task("Identity confirmation")).to have_text("No match")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows identity confirmation question" do
            expect(page).to have_content("Did #{claim.full_name} submit the claim?")
            expect(page).to have_link(href: admin_claim_notes_path(claim))
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows note not matched by automated check" do
            expect(notes).to include(
              have_text("Not matched").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end

      context "with eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new( # 1st September is start of academic year
              claim.eligibility.first_eligible_itt_academic_year.start_year,
              9,
              1
            ),
            itt_subject_codes: [EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES[:mathematics].first]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications passed" do
            expect(task("Qualifications")).to have_text("Passed")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not eligible by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot eligible}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except QTS award date" do
          let(:data) do
            {
              qts_award_date: Date.new(
                claim.eligibility.first_eligible_itt_academic_year.start_year - 1,
                9,
                1
              ),
              itt_subject_codes: [EarlyCareerPayments::DqtRecord::ELIGIBLE_HECOS_CODES[:mathematics].first]
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows qualifications no match" do
              expect(task("Qualifications")).to have_text("No match")
            end
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows qualifications question" do
              expect(page).to have_content("Does the claimant’s initial teacher training (ITT) start/end year and subject match the above information from their claim?")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows note not eligible by automated check" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except ITT subjects codes" do
          let(:data) do
            {
              qts_award_date: Date.new( # 1st September is start of academic year
                claim.eligibility.first_eligible_itt_academic_year.start_year,
                9,
                1
              ),
              itt_subject_codes: ["NoCode"]
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows qualifications no match" do
              expect(task("Qualifications")).to have_text("No match")
            end
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows qualifications question" do
              expect(page).to have_content("Does the claimant’s initial teacher training (ITT) start/end year and subject match the above information from their claim?")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows note not eligible by automated check" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "with admin claims tasks qualifications passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                academic_year: AcademicYear.new(2021),
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: "qualifications")],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :qualifications).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not eligible by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot eligible}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end
      end

      context "without eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new(
              claim.eligibility.first_eligible_itt_academic_year.start_year - 1,
              9,
              1
            ),
            itt_subject_codes: ["NoCode"]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications incomplete" do
            expect(task("Qualifications")).to have_text("No match")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows qualifications question" do
            expect(page).to have_content("Does the claimant’s initial teacher training (ITT) start/end year and subject match the above information from their claim?")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows not eligible by an automated check" do
            expect(notes).to include(
              have_text("Ineligible").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end
    end
  end

  context "with MathsAndPhysics policy" do
    let(:policy) { MathsAndPhysics }

    context "with submitted claim" do
      let(:claim) do
        claimant_submits_claim(
          claim_attributes: {
            date_of_birth: Date.new(1990, 8, 23),
            first_name: "Fred",
            national_insurance_number: "QQ100000C",
            policy: policy,
            reference: "AB123456",
            surname: "ELIGIBLE",
            teacher_reference_number: "1234567"
          }
        )
      end

      context "with matching DQT identity" do
        let(:data) do
          {
            date_of_birth: claim.date_of_birth,
            name: "#{claim.first_name} #{claim.surname}",
            national_insurance_number: claim.national_insurance_number,
            teacher_reference_number: claim.teacher_reference_number
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation passed" do
            expect(task("Identity confirmation")).to have_text("Passed")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not matched by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot matched}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except national insurance number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: "QQ100000B",
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows National Insurance number not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "National Insurance number not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching teacher reference number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: "7654321"
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation incomplete" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows teacher reference number not matched by an automated check" do
              expect(notes).to include(
                have_text("Teacher reference number not matched").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching first name" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows first name or surname not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching surname" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Except",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            context "admin claim notes view" do
              before { visit admin_claim_notes_path(claim) }

              scenario "shows first name or surname not matched by an automated check" do
                expect(notes).to include(
                  have_text(
                    "First name or surname not matched"
                  ).and(
                    have_text(
                      "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                    )
                  )
                )
              end
            end
          end
        end

        context "with middle names" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Middle Names #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Passed")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome performed by automated check" do
              expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by an automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching date of birth" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "with admin claims tasks identity confirmation passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: :identity_confirmation)],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :identity_confirmation).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "with teacher status alert" do
          let(:data) do
            {
              active_alert?: true,
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  within(".banner") do
                    "Teacher’s identity has an active alert. Speak to manager before checking this claim."
                  end
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end

          context "admin claim" do
            before { visit admin_claim_path(claim) }

            scenario "shows note in banner" do
              expect(banner).to have_text("Teacher’s identity has an active alert. Speak to manager before checking this claim.")
            end
          end
        end

        context "except multiple matches" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation partial match" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows multiple not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )

              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end
      end

      context "without matching DQT identity" do
        let(:data) { nil }

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation no match" do
            expect(task("Identity confirmation")).to have_text("No match")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows identity confirmation question" do
            expect(page).to have_content("Did #{claim.full_name} submit the claim?")
            expect(page).to have_link(href: admin_claim_notes_path(claim))
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows note not matched by automated check" do
            expect(notes).to include(
              have_text("Not matched").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end

      context "with eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new( # 1st September is start of academic year
              policy.first_eligible_qts_award_year(claim.academic_year).start_year,
              9,
              1
            ),
            itt_subject_codes: [MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications passed" do
            expect(task("Qualifications")).to have_text("Passed")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not eligible by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot eligible}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except QTS award date" do
          let(:data) do
            {
              qts_award_date: Date.new(
                policy.first_eligible_qts_award_year(claim.academic_year).start_year - 1,
                9,
                1
              ),
              itt_subject_codes: [MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first]
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows qualifications incomplete" do
              expect(task("Qualifications")).to have_text("No match")
            end
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows qualifications question" do
              expect(page).to have_content("Does the claimant’s initial teacher training (ITT) qualification year and specialist subject match the above information from their claim?")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows not eligible by an automated check" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except ITT subjects codes" do
          let(:data) do
            {
              qts_award_date: Date.new( # 1st September is start of academic year
                policy.first_eligible_qts_award_year(claim.academic_year).start_year,
                9,
                1
              ),
              itt_subject_codes: ["NoCode"]
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows qualifications incomplete" do
              expect(task("Qualifications")).to have_text("No match")
            end
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows qualifications question" do
              expect(page).to have_content("Does the claimant’s initial teacher training (ITT) qualification year and specialist subject match the above information from their claim?")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows not eligible by an automated check" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "with admin claims tasks qualifications passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: "qualifications")],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :qualifications).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not eligible by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot eligible}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end
      end

      context "without eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new(
              policy.first_eligible_qts_award_year(claim.academic_year).start_year - 1,
              9,
              1
            ),
            itt_subject_codes: ["NoCode"]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications incomplete" do
            expect(task("Qualifications")).to have_text("No match")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows qualifications question" do
            expect(page).to have_content("Does the claimant’s initial teacher training (ITT) qualification year and specialist subject match the above information from their claim?")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows not eligible by an automated check" do
            expect(notes).to include(
              have_text("Ineligible").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end
    end
  end

  context "with StudentLoans policy" do
    let(:policy) { StudentLoans }

    context "with submitted claim" do
      let(:claim) do
        claimant_submits_claim(
          claim_attributes: {
            date_of_birth: Date.new(1990, 8, 23),
            first_name: "Fred",
            national_insurance_number: "QQ100000C",
            policy: policy,
            reference: "AB123456",
            surname: "ELIGIBLE",
            teacher_reference_number: "1234567"
          }
        )
      end

      context "with matching DQT identity" do
        let(:data) do
          {
            date_of_birth: claim.date_of_birth,
            name: "#{claim.first_name} #{claim.surname}",
            national_insurance_number: claim.national_insurance_number,
            teacher_reference_number: claim.teacher_reference_number
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation passed" do
            expect(task("Identity confirmation")).to have_text("Passed")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not matched by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot matched}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except national insurance number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: "QQ100000B",
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows National Insurance number not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "National Insurance number not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching teacher reference number" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: "7654321"
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation incomplete" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows teacher reference number not matched by an automated check" do
              expect(notes).to include(
                have_text("Teacher reference number not matched").and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching first name" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows first name or surname not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "except matching surname" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Except",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            context "admin claim notes view" do
              before { visit admin_claim_notes_path(claim) }

              scenario "shows first name or surname not matched by an automated check" do
                expect(notes).to include(
                  have_text(
                    "First name or surname not matched"
                  ).and(
                    have_text(
                      "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                    )
                  )
                )
              end
            end
          end
        end

        context "with middle names" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} Middle Names #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Passed")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome performed by automated check" do
              expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by an automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "except matching date of birth" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end

        context "with admin claims tasks identity confirmation passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: :identity_confirmation)],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :identity_confirmation).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :identity_confirmation).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not matched by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot matched}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end

        context "with teacher status alert" do
          let(:data) do
            {
              active_alert?: true,
              date_of_birth: claim.date_of_birth,
              name: "#{claim.first_name} #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation passed" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows date of birth not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  within(".banner") do
                    "Teacher’s identity has an active alert. Speak to manager before checking this claim."
                  end
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end

          context "admin claim" do
            before { visit admin_claim_path(claim) }

            scenario "shows note in banner" do
              expect(banner).to have_text("Teacher’s identity has an active alert. Speak to manager before checking this claim.")
            end
          end
        end

        context "except multiple matches" do
          let(:data) do
            {
              date_of_birth: claim.date_of_birth + 1.day,
              name: "Except #{claim.surname}",
              national_insurance_number: claim.national_insurance_number,
              teacher_reference_number: claim.teacher_reference_number
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows identity confirmation partial match" do
              expect(task("Identity confirmation")).to have_text("Partial match")
            end
          end

          context "admin claim tasks identity confirmation view" do
            before { visit admin_claim_task_path(claim, :identity_confirmation) }

            scenario "shows identity confirmation question" do
              expect(page).to have_content("Did #{claim.full_name} submit the claim?")
              expect(page).to have_link(href: admin_claim_notes_path(claim))
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows multiple not matched by an automated check" do
              expect(notes).to include(
                have_text(
                  "Date of birth not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )

              expect(notes).to include(
                have_text(
                  "First name or surname not matched"
                ).and(
                  have_text(
                    "by an automated check on #{I18n.l(claim.notes.last.created_at)}"
                  )
                )
              )
            end
          end
        end
      end

      context "without matching DQT identity" do
        let(:data) { nil }

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows identity confirmation no match" do
            expect(task("Identity confirmation")).to have_text("No match")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "shows identity confirmation question" do
            expect(page).to have_content("Did #{claim.full_name} submit the claim?")
            expect(page).to have_link(href: admin_claim_notes_path(claim))
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows note not matched by automated check" do
            expect(notes).to include(
              have_text("Not matched").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end

      context "with eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new( # 1st September is start of academic year
              policy.first_eligible_qts_award_year(claim.academic_year).start_year,
              9,
              1
            ),
            itt_subject_codes: ["CODE"]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications passed" do
            expect(task("Qualifications")).to have_text("Passed")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows task outcome performed by automated check" do
            expect(task_outcome).to have_text("This task was performed by an automated check on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "doesn't show not eligible by an automated check" do
            expect(notes).not_to include(
              have_text(%r{[Nn]ot eligible}).and(
                have_text("by an automated check")
              )
            )
          end
        end

        context "except QTS award date" do
          let(:data) do
            {
              qts_award_date: Date.new(
                policy.first_eligible_qts_award_year(claim.academic_year).start_year - 1,
                9,
                1
              ),
              itt_subject_codes: ["CODE"]
            }
          end

          context "admin claim tasks view" do
            before { visit admin_claim_tasks_path(claim) }

            scenario "shows qualifications incomplete" do
              expect(task("Qualifications")).to have_text("No match")
            end
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows qualifications question" do
              expect(page).to have_content("Does the claimant’s initial teacher training (ITT) qualification year match the above information from their claim?")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "shows QTS award date not eligible by an automated check" do
              include(
                have_content(
                  "Not eligible"
                ).and(
                  have_content("by an automated check")
                )
              )
            end
          end
        end

        context "with admin claims tasks qualifications passed" do
          let(:claim) do
            claimant_submits_claim(
              claim_attributes: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                policy: policy,
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: "qualifications")],
                teacher_reference_number: "1234567"
              }
            )
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows task outcome previously performed by user" do
              expect(task_outcome).to have_text("This task was performed by #{claim.tasks.where(name: :qualifications).first.created_by.full_name} on #{I18n.l(claim.tasks.where(name: :qualifications).first.created_at)}")
            end
          end

          context "admin claim notes view" do
            before { visit admin_claim_notes_path(claim) }

            scenario "doesn't show not eligible by automated check" do
              expect(notes).not_to include(
                have_text(%r{[Nn]ot eligible}).and(
                  have_text("by an automated check")
                )
              )
            end
          end
        end
      end

      context "without eligible qualifications" do
        let(:data) do
          {
            qts_award_date: Date.new(
              policy.first_eligible_qts_award_year(claim.academic_year).start_year - 1,
              9,
              1
            ),
            itt_subject_codes: ["NoCode"]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications incomplete" do
            expect(task("Qualifications")).to have_text("No match")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "shows qualifications question" do
            expect(page).to have_content("Does the claimant’s initial teacher training (ITT) qualification year match the above information from their claim?")
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows not eligible by an automated check" do
            expect(notes).to include(
              have_text("Ineligible").and(
                have_text("by an automated check")
              )
            )
          end
        end
      end
    end
  end
end
