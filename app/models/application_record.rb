class ApplicationRecord < ActiveRecord::Base
  include DfE::Analytics::Entities

  self.abstract_class = true
  self.implicit_order_column = :created_at
end
