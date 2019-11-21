module RequestHelpers
  def start_student_loans_claim
    post claims_path(StudentLoans.routing_name), params: {
      claim: {
        eligibility_attributes: {
          qts_award_year: "on_or_after_september_2013",
        },
      },
    }
  end

  def start_maths_and_physics_claim
    post claims_path(MathsAndPhysics.routing_name), params: {
      claim: {
        eligibility_attributes: {
          teaching_maths_or_physics: 1,
        },
      },
    }
  end

  def sign_in_to_admin_with_role(*args)
    stub_dfe_sign_in_with_role(*args)
    post admin_dfe_sign_in_path
    follow_redirect!
  end
end
