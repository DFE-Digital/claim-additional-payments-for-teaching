web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rake jobs:work
release: yarn install && rake db:migrate
