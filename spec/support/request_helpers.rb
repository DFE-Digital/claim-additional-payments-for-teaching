module RequestHelpers
  def start_claim
    post claims_path, params: {
      claim: {
        eligibility_attributes: {
          qts_award_year: "2016_2017",
        },
      },
    }
  end
end
