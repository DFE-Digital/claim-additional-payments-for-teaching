RSpec::Matchers.define :mirror do |expected|
  match do |actual|
    excluded_attributes_for_expected_class = {
      "Claim" => %w[id created_at updated_at eligibility_type eligibility_id],
      "Eligibility" => %w[id created_at updated_at eligible_degree_subject]
    }

    excluded_attributes = excluded_attributes_for_expected_class[expected.class.name.demodulize]

    expected_attributes = expected.attributes.except(*excluded_attributes)
    actual_attributes = actual.attributes.except(*excluded_attributes)

    Hashdiff.diff(expected_attributes, actual_attributes).empty?
  end
end
