DateTime::DATE_FORMATS[:custom_ordinal] = lambda { |time| time.strftime("#{time.day.ordinalize} %B %Y") }
