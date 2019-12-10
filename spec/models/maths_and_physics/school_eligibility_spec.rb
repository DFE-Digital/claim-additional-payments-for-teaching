require "rails_helper"

RSpec.describe MathsAndPhysics::SchoolEligibility do
  describe "#eligible_current_school?" do
    subject { MathsAndPhysics::SchoolEligibility.new(school).eligible_current_school? }
    let(:school) { build(:school, school_attributes.merge({local_authority_district: local_authority_district})) }

    context "when it is in an eligible local authority district" do
      let(:local_authority_district) { local_authority_districts(:barnsley) }

      context "and it is a college" do
        let(:college_attributes) { {school_type_group: :colleges} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { college_attributes.merge({phase: :middle_deemed_secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { college_attributes.merge({phase: :sixteen_plus}) }
          it { is_expected.to be false }
        end
      end

      context "and it is an academy" do
        let(:academy_school_attributes) { {school_type_group: :academies} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { academy_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { academy_school_attributes.merge({phase: :primary}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a free school" do
        let(:free_school_attributes) { {school_type_group: :free_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { free_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { free_school_attributes.merge({phase: :middle_deemed_primary}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a LA maintained school" do
        let(:la_maintained_attributes) { {school_type_group: :la_maintained} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { la_maintained_attributes.merge({phase: :all_through}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { la_maintained_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a state funded special school" do
        let(:special_school_attributes) { {school_type: :community_special_school, school_type_group: :special_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }

          context "and it has a statutory high age of 16" do
            let(:school_attributes) { {statutory_high_age: 16} }
            it { is_expected.to be(true) }
          end
        end
      end

      context "and it is a special free school" do
        let(:special_free_school_attributes) { {school_type: :free_school_special, school_type_group: :free_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }

          context "and it has a statutory high age of 16" do
            let(:school_attributes) { {statutory_high_age: 16} }
            it { is_expected.to be(true) }
          end
        end
      end

      context "and it is an independent special school" do
        let(:special_school_attributes) { {school_type: :other_independent_special_school, school_type_group: :special_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be false }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a special post 16 institution" do
        let(:school_attributes) { {school_type: :special_post_16_institutions, school_type_group: :special_schools, phase: :not_applicable} }
        it { is_expected.to be false }
      end

      context "and it is not a state funded school" do
        let(:school_attributes) { {school_type_group: :independent_schools} }
        it { is_expected.to be false }
      end
    end

    context "when it is not in an eligible local authority district" do
      let(:local_authority_district) { local_authority_districts(:camden) }
      let(:school_attributes) { {} }
      it { is_expected.to be false }
    end

    context "when the school is otherwise eligible but is closed" do
      let(:school) { build(:school, :maths_and_physics_eligible, close_date: Date.yesterday) }
      it { is_expected.to be false }
    end
  end
end
