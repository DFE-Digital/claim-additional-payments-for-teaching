class ImportStudentLoansDataJob < FileImporterJob
  import_with StudentLoansDataImporter
  rescue_with -> { StudentLoansData.delete_all }
end
