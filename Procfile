web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rake jobs:work
release: rake db:schema:load
