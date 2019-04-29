class ClaimsController < ApplicationController
  def new
  end

  def create
    TslrClaim.create!

    redirect_to qts_year_claim_path
  end
end
