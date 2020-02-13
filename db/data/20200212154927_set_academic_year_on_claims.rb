# Run me with `rails runner db/data/20200212154927_set_academic_year_on_claims.rb`

Claim.update_all(academic_year: "2019/2020")
