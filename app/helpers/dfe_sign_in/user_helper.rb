module DfeSignIn
  module UserHelper
    def user_details(user)
      user.full_name.presence || unknown_user(user)
    end

    private

    def unknown_user(user)
      [
        "Unknown user",
        unknown_user_details(user),
      ].join("<br/>").html_safe
    end

    def unknown_user_details(user)
      content_tag(
        :span,
        "(DfE Sign-in ID - #{user.dfe_sign_in_id})",
        class: "govuk-!-font-size-16"
      )
    end
  end
end
