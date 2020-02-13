web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rake jobs:work
postdeploy: bundle exec rake db:schema:load db:seed
