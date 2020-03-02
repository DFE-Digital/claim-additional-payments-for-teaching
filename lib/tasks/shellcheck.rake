desc "Lint with ShellCheck"
task shellcheck: :environment do
  ignored_directories = ["bin/vsp/"].freeze
  excluded_rules = [
    "SC1071" # ShellCheck only supports sh/bash/dash/ksh scripts. Sorry!
  ].freeze

  files = Dir.glob("bin/**/*").reject { |path|
    Dir.exist?(path) || ignored_directories.any? { |directory| path.starts_with?(directory) }
  }

  success = system("shellcheck --exclude=#{excluded_rules.join(",")} #{files.join(" ")}")

  fail unless success
end
