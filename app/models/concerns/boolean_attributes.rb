module BooleanAttributes
  extend ActiveSupport::Concern

  class_methods do
    def attribute(name, type = nil, **options)
      super

      define_method(:"#{name}?") { !!public_send(name) } if type == :boolean
    end
  end
end
