require "rails_helper"

RSpec.describe Claims::DegreeSubjectHelper do
  describe "#dqt_degree_subjects_playback" do
    let(:dbl) { double(dqt_teacher_record: double(degree_names:)) }

    let(:degree_names) { ["test test", "Test McTest", "TEST"] }

    it "titleizes the subjects which are all lowercase and joins with commas" do
      expect(helper.dqt_degree_subjects_playback(dbl)).to eq("Test Test, Test McTest, TEST")
    end
  end
end
