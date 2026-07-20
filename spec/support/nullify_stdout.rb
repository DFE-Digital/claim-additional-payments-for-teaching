RSpec.configure do |config|
  config.around :each do |example|
    nullify_stdout = RSpec.current_example.metadata[:nullify_stdout]

    if nullify_stdout.present?
      original_stdout = $stdout
      original_stderr = $stderr

      $stdout = File.open(File::NULL, "w")
      $stderr = File.open(File::NULL, "w")

      example.run

      $stdout = original_stdout
      $stderr = original_stderr
    else
      example.run
    end
  end
end
