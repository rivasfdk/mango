class ActiveSupport::TimeWithZone
  def as_json(options = {})
    strftime('%Y/%m/%d %I:%M:%S %p')
  end
end
