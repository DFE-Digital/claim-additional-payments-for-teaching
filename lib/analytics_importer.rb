class AnalyticsImporter
  def self.import(model)
    return unless DfE::Analytics.enabled?

    entity_name = model.table_name

    entity_tag = Time.now.strftime("%Y%m%d%H%M%S")
    DfE::Analytics::LoadEntities.new(entity_name: entity_name).run(entity_tag: entity_tag)
    DfE::Analytics::Services::EntityTableChecks.call(
      entity_name: entity_name,
      entity_type: "import_entity_table_check",
      entity_tag: entity_tag
    )
  end
end
