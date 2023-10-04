DateTime::DATE_FORMATS[:custom_ordinal] = lambda { |time| time.strftime("%A #{time.day.ordinalize} %B %Y") }
