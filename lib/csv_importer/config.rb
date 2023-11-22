module CsvImporter
  module Config
    extend ActiveSupport::Concern

    included do
      class_attribute :target_data_model
      class_attribute :append_only
      class_attribute :parse_headers
      class_attribute :mandatory_headers
      class_attribute :batch_size
      class_attribute :transform_rows_with_method
      class_attribute :transform_rows_with_lambda
      class_attribute :skip_row_if_method
      class_attribute :skip_row_if_lambda
    end

    DEFAULT_BATCH_SIZE = 500
    DEFAULT_ROW_TRANSFORM_LAMBDA = ->(row) { row&.to_h }

    class_methods do
      #
      # @param options [Hash] options to be used in the configuration
      # @option options [Class] :target_data_model the target data model
      # @option options [Boolean] :append_only whether to append rows without purging first (defaults to `false`)
      # @option options [Proc] :transform_rows_with the lambda to execute to transform each row (it can also be a method name)
      # @option options [Proc] :skip_row_if the lambda to execute to skip a row (it can also be a method name)
      # @option options [Integer] :batch_size the batch size for each transform and import step (defaults to 500)
      # @option options [Boolean] :parse_headers whether to parse headers or not (defaults to `true`)
      # @option options [Array<String>] :mandatory_headers a list of mandatory headers to validate, if required
      #
      # @return [void]
      #
      def import_options(options = {})
        target_data_model = options[:target_data_model] || raise(UndefinedDataModelError)
        append_only = (!options[:append_only].nil?) ? options[:append_only] : false
        transform_rows_with = options[:transform_rows_with] || DEFAULT_ROW_TRANSFORM_LAMBDA
        skip_row_if = options[:skip_row_if]
        batch_size = options[:batch_size] || DEFAULT_BATCH_SIZE
        parse_headers = (!options[:parse_headers].nil?) ? options[:parse_headers] : true
        mandatory_headers = options[:mandatory_headers] || []

        self.target_data_model = target_data_model
        self.append_only = append_only
        self.parse_headers = parse_headers
        self.mandatory_headers = mandatory_headers

        if transform_rows_with.is_a?(Symbol)
          self.transform_rows_with_method = transform_rows_with
        elsif transform_rows_with&.lambda?
          self.transform_rows_with_lambda = transform_rows_with
        end

        self.batch_size = batch_size

        return unless skip_row_if

        if skip_row_if.is_a?(Symbol)
          self.skip_row_if_method = skip_row_if
        elsif skip_row_if&.lambda?
          self.skip_row_if_lambda = skip_row_if
        end

        nil
      end
    end
  end
end
