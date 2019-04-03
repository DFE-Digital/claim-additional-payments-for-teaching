if Rails.env.development? || Rails.env.test?
  desc 'Run rubocop - configure in .rubocop.yml'
  task :rubocop do
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:rubocop) do |t|
      t.options = ['--display-cop-names']
    end
  end
end
