require "rails_helper"

describe ClaimsHelper do
  describe "#options_for_qts_award_year" do
    it "returns an array of the valid years as label/value pairs for use as select options" do
      expected_options = [
        ["September 1 2013 - August 31 2014", "2013-2014"],
        ["September 1 2014 - August 31 2015", "2014-2015"],
        ["September 1 2015 - August 31 2016", "2015-2016"],
        ["September 1 2016 - August 31 2017", "2016-2017"],
        ["September 1 2017 - August 31 2018", "2017-2018"],
        ["September 1 2018 - August 31 2019", "2018-2019"],
        ["September 1 2019 - August 31 2020", "2019-2020"],
      ]

      expect(helper.options_for_qts_award_year).to eq expected_options
    end
  end
end
