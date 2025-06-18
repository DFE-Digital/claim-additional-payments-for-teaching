class FileImporterJob < ApplicationJob
  class InvalidImporterError < StandardError; end

  class_attribute :importer_class
  class_attribute :post_import_block
  class_attribute :rescue_with_lambda
  class_attribute :notify_with_mailer
  class_attribute :success_mailer_method
  class_attribute :failure_mailer_method

  class_attribute :file_upload_id
  class_attribute :uploaded_by_email

  class << self
    def import_with(importer_class, &block)
      raise InvalidImporterError unless importer_class.is_a?(Class) && importer_class.method_defined?(:run)

      self.importer_class = importer_class
      self.post_import_block = block if block
    end

    def rescue_with(func)
      self.rescue_with_lambda = func if func&.lambda?
    end

    def notify_with(notify_with_mailer, success:, failure:)
      self.notify_with_mailer = notify_with_mailer.to_s.constantize
      self.success_mailer_method = success
      self.failure_mailer_method = failure
    end
  end

  def perform(file_upload_id)
    raise ActiveRecord::RecordNotFound unless FileUpload.exists?(id: file_upload_id)

    self.file_upload_id = file_upload_id
    uploaded_by = FileUpload.find(file_upload_id).uploaded_by
    self.uploaded_by_email = uploaded_by.email

    ingest!
    send_success_email if uploaded_by_email
    post_import_block&.call(uploaded_by)
  rescue => e
    Rollbar.error(e)
    Sentry.capture_exception(e)

    rescue_with_lambda&.call
    send_failure_email if uploaded_by_email
  end

  private

  def ingest!
    # NOTE: the `body` column is a large blob, use pluck to stream it straight into a file and not in memory
    Tempfile.new.tap do |file|
      file.write(FileUpload.where(id: file_upload_id).pluck(:body).first)
      file.rewind
      importer_class.new(file).run
      file.close!
    end

    FileUpload.delete(file_upload_id)
  end

  def send_success_email
    return unless notify_with_mailer && success_mailer_method

    notify_with_mailer.public_send(success_mailer_method, uploaded_by_email).deliver_now
  end

  def send_failure_email
    return unless notify_with_mailer && failure_mailer_method

    notify_with_mailer.public_send(failure_mailer_method, uploaded_by_email).deliver_now
  end
end
