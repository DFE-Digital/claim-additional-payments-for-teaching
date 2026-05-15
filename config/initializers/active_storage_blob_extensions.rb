# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_blob) do
  self::MALWARE_SCAN_RESULT_PASSED = "passed"
  self::MALWARE_SCAN_RESULT_FAILED = "failed"
  self::MALWARE_SCAN_RESULT_SKIPPED = "skipped"
  self::MALWARE_SCAN_RESULT_UNRECOGNISED = "defender_result_unrecognised"

  def malware_scan_pending?
    malware_scan_result.nil?
  end

  def malware_scan_passed?
    malware_scan_result == self.class::MALWARE_SCAN_RESULT_PASSED
  end

  def malware_scan_failed?
    malware_scan_result == self.class::MALWARE_SCAN_RESULT_FAILED
  end

  def malware_scan_skipped?
    malware_scan_result == self.class::MALWARE_SCAN_RESULT_SKIPPED
  end

  def malware_scan_result_unrecognised?
    malware_scan_result == self.class::MALWARE_SCAN_RESULT_UNRECOGNISED
  end
end
