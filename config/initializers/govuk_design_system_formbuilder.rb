GOVUKDesignSystemFormBuilder.configure do |c|
  c.default_collection_radio_buttons_auto_bold_labels = false
end

require_relative "../../lib/govuk_design_system_form_builder/govuk_school_search"
GOVUKDesignSystemFormBuilder::FormBuilder.include(GOVUKSchoolSearch)
