module TestSeeders
  class DecisionsImporter
    DECISION_COLUMNS = [
      :claim_id,
      :created_by_id,
      :result,
      :notes,
      :created_at,
      :updated_at
    ].freeze

    def initialize(claim_ids, admin_approver)
      @claim_ids = claim_ids
      @admin_approver = admin_approver
      @logger = Logger.new($stdout)
    end

    def run
      logger.info "Seeding #{claim_ids.size} Decisions"
      insert_decisions
    end

    private

    attr_reader :logger, :claim_ids, :admin_approver

    def insert_decisions
      logger.info "Inserting decisions as #{admin_approver.role_codes.first}"
      Decision.copy_from_client DECISION_COLUMNS do |copy|
        claim_ids.each do |claim_id|
          time = Time.now.getutc

          copy << [
            claim_id,
            admin_approver.id,
            0,
            nil,
            time,
            time
          ]
        end
      end
    end
  end
end
