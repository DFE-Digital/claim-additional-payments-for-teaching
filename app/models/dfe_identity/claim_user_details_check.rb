module DfeIdentity
  class ClaimUserDetailsCheck
    def self.call(claim, result)
      new(claim, result).save_details_check_result
    end

    def initialize(claim, result)
      @claim = claim
      @result = result
    end

    def save_details_check_result
      return unless ["true", "false"].include?(@result)

      @claim.update(details_check: @result)

      if @result == "true"
        ClaimUserDetailsUpdater.call(@claim)
      else
        ClaimUserDetailsReset.call(@claim, :details_incorrect)
      end

      @result == "true"
    end
  end
end
