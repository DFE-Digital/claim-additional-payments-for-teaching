web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rake jobs:work
postdeploy: rake db:schema:load db:seed
