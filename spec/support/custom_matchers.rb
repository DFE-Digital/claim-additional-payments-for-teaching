RSpec::Matchers.define :mirror do |expected|
  match do |actual|
    excluded_attrs_for_class = {
      "Claim" => %w[id created_at updated_at eligibility_type eligibility_id],
      "Eligibility" => %w[id created_at updated_at eligible_degree_subject]
    }

    excluded_attrs = excluded_attrs_for_class[actual.class.name.demodulize]
    mismatched_attrs = (actual.attributes.to_a - expected.attributes.to_a).map(&:first) - excluded_attrs

    unless mismatched_attrs.empty?
      Rails.logger.info("ACTUAL attrs: #{actual.attributes.to_a.inspect}")
      Rails.logger.info("EXPECTED attrs: #{expected.attributes.to_a.inspect}")
      Rails.logger.info("attrs: #{mismatched_attrs.inspect}")
    end

    mismatched_attrs.empty?
  end
end
