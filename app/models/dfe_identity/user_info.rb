module DfeIdentity
  class UserInfo
    include ActiveModel::Model

    attr_accessor :trn, :birthdate, :given_name, :family_name, :ni_number, :trn_match_ni_number

    validates :trn, presence: true
    validates :birthdate, presence: true
    validates :given_name, presence: true
    validates :family_name, presence: true
    validates :ni_number, presence: true
    validates_format_of :trn_match_ni_number, with: /(true|false)/i

    def self.validated?(user_info)
      new(from_params(user_info)).validated?
    rescue ActiveModel::UnknownAttributeError
      false
    end

    def self.attributes
      instance_methods(false).grep(/^(\w+)=$/) { $1 }
    end

    def self.from_params(params)
      (params || {}).slice(*attributes)
    end

    def validated?
      !!(valid? && trn_match_ni_number =~ /true/i)
    end
  end
end
