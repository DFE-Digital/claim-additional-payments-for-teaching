require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::IttYearForm, type: :model do
  let(:current_academic_year) { AcademicYear.new(2024) }

  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments,
      current_academic_year: current_academic_year
    )
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        eligible_itt_subject: "mathematics" # reset if answers changed
      }
    )
  end

  let(:params) do
    {}
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    before do
      journey_session.answers.assign_attributes(
        qualification: :postgraduate_itt
      )

      journey_session.save!
    end

    it do
      is_expected.to validate_inclusion_of(:itt_academic_year).in_array(
        [
          "2019/2020",
          "2020/2021",
          "2021/2022",
          "2022/2023",
          "2023/2024",
          "itt_academic_year_none"
        ]
      ).with_message("Select the academic year you started your postgraduate ITT")
    end
  end

  describe "#save" do
    context "when invalid" do
      it "returns false and does not save the journey session" do
        expect { expect(form.save).to be(false) }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end

    context "when valid" do
      let(:academic_year) { AcademicYear.new(2022) }
      let(:params) do
        {
          itt_academic_year: academic_year.to_s
        }
      end

      context "when none of the above is selected" do
        let(:params) do
          {
            itt_academic_year: "itt_academic_year_none"
          }
        end

        it "saves the year as a none AcademicYear" do
          expect { expect(form.save).to be(true) }.to(
            change { journey_session.reload.answers.itt_academic_year }
            .from(nil).to(AcademicYear.new(nil))
          )
        end
      end

      context "when itt_academic_year has changed" do
        before do
          journey_session.answers.assign_attributes(
            itt_academic_year: AcademicYear.new(2021)
          )

          journey_session.save!
        end

        context "when qualifications_details_check is not true" do
          it "updates the session and resets the dependent answers" do
            expect { expect(form.save).to be(true) }.to(
              change { journey_session.reload.answers.itt_academic_year }
              .from(AcademicYear.new(2021)).to(academic_year)
              .and(
                change { journey_session.reload.answers.eligible_itt_subject }
                .from("mathematics").to(nil)
              )
            )
          end
        end

        context "when qualifications_details_check is true" do
          before do
            journey_session.answers.assign_attributes(
              qualifications_details_check: true
            )

            journey_session.save!
          end

          it "updates the session and does not reset the dependent answers" do
            expect { expect(form.save).to be(true) }.to(
              change { journey_session.reload.answers.itt_academic_year }
              .from(AcademicYear.new(2021)).to(academic_year)
              .and(
                not_change { journey_session.reload.answers.eligible_itt_subject }
              )
            )
          end
        end
      end

      context "when itt_academic_year has not changed" do
        before do
          journey_session.answers.assign_attributes(
            itt_academic_year: academic_year
          )

          journey_session.save!
        end

        it "updates the session and does not reset the dependent answers" do
          expect { expect(form.save).to be(true) }.to(
            not_change { journey_session.reload.answers.itt_academic_year }
            .from(academic_year)
            .and(
              not_change { journey_session.reload.answers.eligible_itt_subject }
            )
          )
        end
      end
    end
  end
end
