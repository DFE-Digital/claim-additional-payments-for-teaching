class AnalyticsImporter
  def self.import(model)
    Rake::Task["dfe:analytics:import_entity"].invoke(model.table_name) if DfE::Analytics.enabled?
  end
end
