module TeacherId
  class Config
    def self.instance
      @instance ||= new
    end

    def bypass?
      (Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")) && ENV["BYPASS_DFE_SIGN_IN"] == "true"
    end
  end
end
