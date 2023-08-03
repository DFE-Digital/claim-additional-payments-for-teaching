module SessionAccessor
  def session
    Thread.current[:session]
  end
  
  def self.session=(session_data)
    Thread.current[:session] = session_data
  end
end