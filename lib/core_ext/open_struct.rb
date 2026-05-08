require "ostruct"

module CoreExt
  module OpenStruct
    def as_json(options = nil)
      if (options || {})[:without_table]
        @table.as_json(options)
      else
        super
      end
    end
  end
end

OpenStruct.include CoreExt::OpenStruct
