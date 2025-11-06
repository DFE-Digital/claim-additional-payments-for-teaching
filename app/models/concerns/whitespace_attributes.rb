module WhitespaceAttributes
  extend ActiveSupport::Concern

  included do
    class_attribute :strip_whitespace_attributes,
      default: [],
      instance_writer: false,
      instance_predicate: false

    class_attribute :strip_all_whitespace_attributes,
      default: [],
      instance_writer: false,
      instance_predicate: false

    before_validation do
      strip_whitespace_attributes.each do |attr|
        if attribute_names.include?(attr.to_s) && public_send(attr)
          public_send("#{attr}=", public_send(attr).strip)
        end
      end

      strip_all_whitespace_attributes.each do |attr|
        if attribute_names.include?(attr.to_s) && public_send(attr)
          public_send("#{attr}=", public_send(attr).gsub(/\s/, ""))
        end
      end
    end
  end

  class_methods do
    def attribute(name, type = nil, **options)
      strip_all_whitespace_flag = options.delete(:strip_all_whitespace)
      keep_whitespace_flag = options.delete(:keep_whitespace)

      if type == :string && keep_whitespace_flag
        # noop
      elsif type == :string && strip_all_whitespace_flag
        strip_all_whitespace_attributes << name
      elsif type == :string
        strip_whitespace_attributes << name
      end

      super
    end
  end
end
