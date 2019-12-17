namespace :brakeman do
  desc "Run Brakeman"
  task :run do
    require "brakeman"

    result = Brakeman.run(
      app_path: ".",
      quiet: true,
      pager: false,
      print_report: true
    )

    exit Brakeman::Warnings_Found_Exit_Code unless result.filtered_warnings.empty?
    exit Brakeman::Errors_Found_Exit_Code unless result.errors.empty?
  end
end
