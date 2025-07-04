module DfeSignIn
  class NullUser < User
    def null_user?
      true
    end

    def is_service_operator?
      false
    end
  end
end
