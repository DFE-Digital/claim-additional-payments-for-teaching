class InvalidDate
  include ActiveModel::Model

  attr_accessor :day, :month, :year

  def future?
    false
  end
end
