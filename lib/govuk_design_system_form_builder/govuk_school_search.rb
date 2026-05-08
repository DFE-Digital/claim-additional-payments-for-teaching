module GOVUKSchoolSearch
  def govuk_school_search(method, tag_value, options = {})
    if options.empty?
      options = tag_value
    end

    # Hidden field we write selected option to
    result_attribute = options.fetch(:result_attribute)

    hidden_field_id = [@object_name, result_attribute, "hidden"].join("-")

    hidden_field = @template.hidden_field(
      @object_name,
      result_attribute,
      id: hidden_field_id
    )

    search_path = options.fetch(:search_path)

    search_box = govuk_text_field(
      method,
      **options.slice(:label, :hint)
    )

    @template.content_tag(
      :div,
      data: {
        school_search_container: true,
        school_search_path: search_path,
        school_search_school_id_target: "##{hidden_field_id}",
        school_search_min_length: 3
      },
      class: "govuk-!-margin-bottom-4"
    ) do
      safe_join([
        hidden_field,
        search_box
      ])
    end
  end
end
