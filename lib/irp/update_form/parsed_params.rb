class UpdateForm::ParsedParams
  def initialize(params)
    @params = params
    @date_params_regex = /(.*)\((\d)i\)/
    @multi_params_regex = /\(\di\)/
    @date_keys = {
      1 => :year,
      2 => :month,
      3 => :day,
    }
  end
  attr_reader :params

  def execute
    params_without_date.merge(sanitize_date_params)
  end

private

  def params_without_date
    params.to_hash.reject { _1 =~ @multi_params_regex }
  end

  def sanitize_date_params
    params
      .to_hash
      .select { _1 =~ @multi_params_regex }
      .each_with_object({}, &method(:build_date_input_args))
      .each_with_object({}, &method(:instanciate_date))
  end

  def build_date_input_args((k, v), hash)
    md = @date_params_regex.match(k)
    key = md[1]
    indice = @date_keys.fetch(md[2].to_i)

    hash[key] ||= {}
    hash[key][indice] = v.blank? ? nil : v.to_i
    hash
  end

  def instanciate_date((field, args), hash)
    hash[field] = Date.new(args[:year], args[:month], args[:day])
    hash
  rescue StandardError
    hash[field] = nil
    hash
  end
end
