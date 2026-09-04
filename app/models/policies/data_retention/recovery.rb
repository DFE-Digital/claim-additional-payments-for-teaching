module Policies
  module DataRetention
    class Recovery < ApplicationRecord
      belongs_to :claim
    end
  end
end
