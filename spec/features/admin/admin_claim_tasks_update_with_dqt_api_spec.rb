require "rails_helper"

RSpec.feature "Admin claim tasks update with DQT API" do
  def claimant_submits_claim(claim_attributes:, answers:, post_submission_claim_attributes: {})
    in_browser(:claimant) do
      policy = claim_attributes[:policy]
      policy_underscored = policy.to_s.underscore
      send(:"start_#{policy_underscored}_claim")

      journey = Journeys.for_policy(policy)

      journey_session = journey::Session.last

      journey_session.answers.assign_attributes(
        attributes_for(
          :"#{journey.i18n_namespace}_answers",
          :submittable
        ).merge(answers)
      )

      journey_session.save!

      jump_to_claim_journey_page(
        slug: "check-your-answers",
        journey_session: journey_session
      )

      (claim_attributes[:policy] == Policies::EarlyCareerPayments) ? click_on("Accept and send") : click_on("Confirm and send")
    end

    submitted_claim = Claim.by_policy(claim_attributes[:policy]).order(:created_at).last

    submitted_claim.update!(post_submission_claim_attributes)

    submitted_claim
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
    page.find("div", class: ["govuk-inset-text task-outcome"])
  end

  before do
    create(:journey_configuration, :student_loans)

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
          qts_date: (data[:qts_award_date] || Date.today).to_s,
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
          programme_start_date: (data[:itt_start_date] || "2020-07-04T00:00:00Z").to_s,
          programme_end_date: "2021-07-04T00:00:00Z",
          programme_type: "Overseas Trained Teacher Programme",
          result: "Pass",
          subject1: data.dig(:itt_subjects, 0).to_s,
          subject1_code: data.dig(:itt_subject_codes, 0).to_s,
          subject2: data.dig(:itt_subjects, 1).to_s,
          subject2_code: data.dig(:itt_subject_codes, 1).to_s,
          subject3: data.dig(:itt_subjects, 2).to_s,
          subject3_codes: data.dig(:itt_subject_codes, 2).to_s,
          qualification: (data[:qualification_name] || "Postgraduate Certificate in Education").to_s,
          state: 0,
          state_name: "Active"
        }
      }

      status = 200
    end

    stub_request(:get, "#{ENV["DQT_API_URL"]}teachers/#{claim.eligibility.teacher_reference_number}")
      .with(query: WebMock::API.hash_including({
        birthdate: claim.date_of_birth.to_s,
        nino: claim.national_insurance_number
      }))
      .to_return(
        body: body.to_json,
        status: status,
        headers: {"Content-Type" => "application/json"}
      )

    perform_enqueued_jobs
  end

  let(:note_body) do
    <<~HTML
      Ineligible:
      <pre>
        ITT subjects: ["Theology and the Universe", "", ""]
        ITT subject codes:  ["TT100", "", ""]
        Degree codes:       []
        ITT start date:     2015-09-01
        QTS award date:     2014-09-01
        Qualification name: BA
      </pre>
    HTML
  end

  let(:first_eligible_itt_academic_year) {
    subject_symbol = claim.eligibility.eligible_itt_subject.to_sym

    policy = claim.eligibility.policy

    claim_year = policy.current_academic_year

    itt_years = policy.selectable_itt_years_for_claim_year(claim_year)

    itt_years.detect do |itt_year|
      subject_symbol.in?(
        policy.current_subject_symbols(
          claim_year: claim_year,
          itt_year: itt_year
        )
      )
    end
  }

  context "with StudentLoans policy" do
    let(:policy) { Policies::StudentLoans }

    context "with submitted claim" do
      let(:claim) do
        claimant_submits_claim(
          answers: {
            date_of_birth: Date.new(1990, 8, 23),
            first_name: "Fred",
            national_insurance_number: "AB100000C",
            surname: "ELIGIBLE",
            teacher_reference_number: "1234567"
          },
          claim_attributes: {
            policy: policy,
            reference: "AB123456"
          }
        )
      end

      context "with matching DQT identity" do
        let(:data) do
          {
            date_of_birth: claim.date_of_birth,
            name: "#{claim.first_name} #{claim.surname}",
            national_insurance_number: claim.national_insurance_number,
            teacher_reference_number: claim.eligibility.teacher_reference_number
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
              national_insurance_number: "AB100000B",
              teacher_reference_number: claim.eligibility.teacher_reference_number
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

            scenario "shows the notes added as part of automated identity checking" do
              expect(notes).to include(
                have_text("National Insurance number not matched").and(
                  have_text("Claimant: \"#{claim.national_insurance_number}\"").and(
                    have_text("DQT: \"AB100000B\"").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
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

            scenario "shows the notes added as part of automated identity checking" do
              expect(notes).to include(
                have_text("Teacher reference number not matched").and(
                  have_text("Claimant: \"#{claim.eligibility.teacher_reference_number}\"").and(
                    have_text("DQT: \"7654321\"").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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

            scenario "shows the notes added as part of automated identity checking" do
              expect(notes).to include(
                have_text("First name or surname not matched").and(
                  have_text("Claimant: \"#{claim.full_name}\"").and(
                    have_text("DQT: \"Except #{claim.surname}\"").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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

            scenario "shows the notes added as part of automated identity checking" do
              expect(notes).to include(
                have_text("First name or surname not matched").and(
                  have_text("Claimant: \"#{claim.full_name}\"").and(
                    have_text("DQT: \"#{claim.first_name} Except\"").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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

            scenario "shows the notes added as part of automated identity checking" do
              expect(notes).to include(
                have_text("Date of birth not matched").and(
                  have_text("Claimant: \"#{claim.date_of_birth}\"").and(
                    have_text("DQT: \"#{claim.date_of_birth + 1.day}\"").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
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
              answers: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "AB100000C",
                surname: "ELIGIBLE",
                teacher_reference_number: "1234567"
              },
              claim_attributes: {
                policy: policy,
                reference: "AB123456"
              },
              post_submission_claim_attributes: {
                tasks: [build(:task, name: :identity_confirmation)]
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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
                  within("section.banner") do
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
              teacher_reference_number: claim.eligibility.teacher_reference_number
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

          scenario "shows the notes added as part of automated identity checking" do
            expect(notes).to include(
              have_text("Not matched").and(
                have_text("by an automated check")
              )
            )
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
              2014,
              9,
              1
            ),
            itt_subjects: ["Mathematics"],
            itt_subject_codes: ["100403"]
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

          scenario "shows the notes added as part of qualification checking" do
            expect(notes).to include(
              have_text("Eligible").and(
                have_text("Mathematics").and(
                  have_text("100403")
                )
              )
            )
          end

          scenario "note doesn't show by an automated check" do
            expect(notes).not_to include(
              have_text("by an automated check")
            )
          end

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
              itt_subjects: ["A Ineligible SUBJECT"],
              itt_subject_codes: ["821009"]
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

            scenario "shows the notes added as part of qualification checking" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("A Ineligible SUBJECT").and(
                    have_text("821009").and(
                      have_text("by an automated check")
                    )
                  )
                )
              )
            end

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

        context "with manually confirmed admin claim tasks qualifications passed" do
          let(:claim) do
            claimant_submits_claim(
              answers: {
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "AB100000C",
                surname: "ELIGIBLE",
                teacher_reference_number: "1234567"
              },
              claim_attributes: {
                policy: policy,
                reference: "AB123456"
              },
              post_submission_claim_attributes: {
                tasks: [build(:task, name: "qualifications")],
                notes: [build(:note, :automated, body: note_body, label: "qualifications")]
              }
            )
          end

          context "admin claim tasks qualifications view" do
            before { visit admin_claim_task_path(claim, :qualifications) }

            scenario "shows the notes added as part of qualification checking" do
              expect(notes).to include(
                have_text("Ineligible").and(
                  have_text("ITT subject codes: [\"TT100\", \"\", \"\"]")
                )
              )
            end

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
            itt_subjects: ["Student Loans Ineligible Subject"],
            itt_subject_codes: ["010101"]
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

          scenario "shows the notes added as part of qualification checking" do
            expect(notes).to include(
              have_text("Ineligible").and(
                have_text("Student Loans Ineligible Subject").and(
                  have_text("by an automated check")
                )
              )
            )
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
