namespace :export do
  desc "Export claims data for school check emails. Specify the claims to exclude by passing a comma-separated list of claim references in the CLAIM_REFERENCES_TO_EXCLUDE environment variable."
  task school_check: :environment do
    comma_separated_claim_references_to_exclude = ENV["CLAIM_REFERENCES_TO_EXCLUDE"]
    raise "You must specify the CLAIM_REFERENCES_TO_EXCLUDE environment variable" if comma_separated_claim_references_to_exclude.blank?

    puts Claim::SchoolCheckEmailDataExport.new(comma_separated_claim_references_to_exclude).csv_string
  end
end
