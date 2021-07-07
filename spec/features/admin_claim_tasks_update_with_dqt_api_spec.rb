require "rails_helper"

RSpec.feature "Admin claim tasks update with DQT API" do
  def claimant_submits_claim(claim_attributes:)
    claim = nil

    in_browser(:claimant) do
      claim = start_maths_and_physics_claim
      claim_attributes[:policy] = MathsAndPhysics

      claim.update!(
        attributes_for(
          :claim,
          :submittable,
          **claim_attributes
        )
      )

      claim.eligibility.update!(
        attributes_for(
          :maths_and_physics_eligibility,
          :eligible,
          initial_teacher_training_subject: :maths
        )
      )

      visit claim_path(claim.policy.routing_name, "check-your-answers")
      click_on "Confirm and send"
    end

    claim
  end

  def in_browser(name)
    current_session = Capybara.session_name
    Capybara.session_name = name
    yield
    Capybara.session_name = current_session
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
      body = <<~JSON
        {
          "data": null,
          "message": "No records found."
        }
      JSON

      status = 404
    else
      body = <<~JSON
        {
          "data": [
            {
              "trn": "#{data[:teacher_reference_number]}",
              "name": "#{data[:name]}",
              "doB": "#{data[:date_of_birth] || Date.today}",
              "niNumber": "#{data[:national_insurance_number]}",
              "qtsAwardDate": "#{data[:qts_award_date] || Date.today}",
              "ittSubject1Code": "#{data.dig(:itt_subject_codes, 0)}",
              "ittSubject2Code": "#{data.dig(:itt_subject_codes, 1)}",
              "ittSubject3Code": "#{data.dig(:itt_subject_codes, 2)}",
              "activeAlert": true
            }
          ],
          "message": null
        }
      JSON

      status = 200
    end

    stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status").with(
      query: WebMock::API.hash_including(
        {
          trn: claim.teacher_reference_number,
          niNumber: claim.national_insurance_number
        }
      )
    ).to_return(body: body, status: status)

    perform_enqueued_jobs
  end

  context "with submitted claim" do
    let(:claim) do
      claimant_submits_claim(
        claim_attributes: {
          date_of_birth: Date.new(1990, 8, 23),
          first_name: "Fred",
          national_insurance_number: "QQ100000C",
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
            expect(task("Identity confirmation")).to have_text("Incomplete")
          end
        end

        context "admin claim tasks identity confirmation view" do
          before { visit admin_claim_task_path(claim, :identity_confirmation) }

          scenario "doesn't show task outcome" do
            expect { task_outcome }.to raise_error(Capybara::ElementNotFound)
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
    end

    context "without matching DQT identity" do
      let(:data) { nil }

      context "admin claim tasks view" do
        before { visit admin_claim_tasks_path(claim) }

        scenario "shows identity confirmation incomplete" do
          expect(task("Identity confirmation")).to have_text("Incomplete")
        end
      end

      context "admin claim tasks identity confirmation view" do
        before { visit admin_claim_task_path(claim, :identity_confirmation) }

        scenario "doesn't show task outcome" do
          expect { task_outcome }.to raise_error(Capybara::ElementNotFound)
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
            MathsAndPhysics.first_eligible_qts_award_year(claim.academic_year).start_year,
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
              MathsAndPhysics.first_eligible_qts_award_year(claim.academic_year).start_year - 1.year,
              9,
              1
            ),
            itt_subject_codes: [MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications incomplete" do
            expect(task("Qualifications")).to have_text("Incomplete")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "doesn't show task outcome" do
            expect { task_outcome }.to raise_error(Capybara::ElementNotFound)
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows QTS award date not eligible by an automated check" do
            expect(notes).to include(
              have_content(
                "QTS award date not eligible"
              ).and(
                have_content("by an automated check")
              )
            )
          end
        end
      end

      context "except ITT subjects codes" do
        let(:data) do
          {
            qts_award_date: Date.new( # 1st September is start of academic year
              MathsAndPhysics.first_eligible_qts_award_year(claim.academic_year).start_year,
              9,
              1
            ),
            itt_subject_codes: ["NoCode"]
          }
        end

        context "admin claim tasks view" do
          before { visit admin_claim_tasks_path(claim) }

          scenario "shows qualifications incomplete" do
            expect(task("Qualifications")).to have_text("Incomplete")
          end
        end

        context "admin claim tasks qualifications view" do
          before { visit admin_claim_task_path(claim, :qualifications) }

          scenario "doesn't show task outcome" do
            expect { task_outcome }.to raise_error(Capybara::ElementNotFound)
          end
        end

        context "admin claim notes view" do
          before { visit admin_claim_notes_path(claim) }

          scenario "shows ITT subject codes not eligible by an automated check" do
            expect(notes).to include(
              have_content(
                "ITT subject codes not eligible"
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
            MathsAndPhysics.first_eligible_qts_award_year(claim.academic_year).start_year - 1.year,
            9,
            1
          ),
          itt_subject_codes: ["NoCode"]
        }
      end

      context "admin claim tasks view" do
        before { visit admin_claim_tasks_path(claim) }

        scenario "shows qualifications incomplete" do
          expect(task("Qualifications")).to have_text("Incomplete")
        end
      end

      context "admin claim tasks qualifications view" do
        before { visit admin_claim_task_path(claim, :qualifications) }

        scenario "doesn't show task outcome" do
          expect { task_outcome }.to raise_error(Capybara::ElementNotFound)
        end
      end

      context "admin claim notes view" do
        before { visit admin_claim_notes_path(claim) }

        scenario "shows not eligible by an automated check" do
          expect(notes).to include(
            have_text("Not eligible").and(
              have_text("by an automated check")
            )
          )
        end
      end
    end
  end
end
