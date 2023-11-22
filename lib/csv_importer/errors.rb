module CsvImporter
  class UndefinedDataModelError < StandardError
    def message
      "You must specify the underlying data model with `import_options target_data_model: CustomModel`"
    end
  end
end
