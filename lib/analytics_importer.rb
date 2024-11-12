class AnalyticsImporter
  ANALYTICS_SYNC_TASK = "dfe:analytics:import_entity"

  def self.import(model)
    return unless DfE::Analytics.enabled?

    if Rake::Task.tasks.map(&:name).exclude?(ANALYTICS_SYNC_TASK)
      Rails.application.load_tasks
    end

    Rake::Task[ANALYTICS_SYNC_TASK].invoke(model.table_name)
  end
end
