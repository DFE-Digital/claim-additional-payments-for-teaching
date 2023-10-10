module DfeIdentity
  class UserInfo
    include ActiveModel::Model

    attr_accessor :trn, :birthdate, :given_name, :family_name, :ni_number, :trn_match_ni_number

    validates :trn, presence: true
    validates :birthdate, presence: true
    validates :given_name, presence: true
    validates :family_name, presence: true
    validates :ni_number, presence: true
    validates :trn_match_ni_number, presence: true, inclusion: {in: %w[true false]}

    def self.validated?(user_info)
      UserInfo.new(user_info).validated?
    rescue ActiveModel::UnknownAttributeError
      false
    end

    def validated?
      valid? && trn_match_ni_number == "true"
    end
  end
end
