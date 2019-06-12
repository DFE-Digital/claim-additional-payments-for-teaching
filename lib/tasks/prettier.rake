if Rails.env.development? || Rails.env.test?
  file_glob = "./**/*.{css,html,js,js.erb,json,md,scss}"

  desc "Lint with Prettier"
  task prettier: :environment do
    success = system("node_modules/.bin/prettier --check " + file_glob)

    fail unless success
  end

  desc "Run prettier on everything not managed by standard"
  desc "Lint and automatically fix with Prettier"
  task "prettier:fix": :environment do
    success = system("node_modules/.bin/prettier --write " + file_glob)

    fail unless success
  end
end
