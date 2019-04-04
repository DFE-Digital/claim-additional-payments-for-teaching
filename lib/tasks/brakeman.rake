if Rails.env.development? || Rails.env.test?
  namespace :brakeman do
    desc 'Run Brakeman'
    task :run do
      require 'brakeman'

      Brakeman.run(
        app_path: '.',
        quiet: true,
        pager: false,
        print_report: true
      )
    end
  end
end
