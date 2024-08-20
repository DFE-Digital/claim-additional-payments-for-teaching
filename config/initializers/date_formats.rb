DateTime::DATE_FORMATS[:custom_ordinal] = lambda { |time| time.strftime("%A #{time.day.ordinalize} %B %Y") }
DateTime::DATE_FORMATS[:govuk_date] = lambda { |time| time.strftime("%d-%m-%Y") }
DateTime::DATE_FORMATS[:long_date] = lambda { |time| time.strftime("%-d %B %Y") }
