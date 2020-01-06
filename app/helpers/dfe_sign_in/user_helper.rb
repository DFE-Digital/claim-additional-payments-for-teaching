module DfeSignIn
  module UserHelper
    def user_details(user, include_line_break: true)
      user.full_name.presence || unknown_user(user, include_line_break)
    end

    private

    def unknown_user(user, include_line_break)
      join_chr = include_line_break == true ? "<br/>" : " "

      [
        "Unknown user",
        unknown_user_details(user),
      ].join(join_chr).html_safe
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
