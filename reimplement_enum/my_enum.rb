module MyEnum
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def enum(definitions)
      definitions.keys.each do |column_name|
        statuses =
          case definitions[column_name]
          when Array
            definitions[column_name].each_with_object({}).with_index { |(status_name, hash), status_num| hash[status_name] = status_num }
          when Hash
            definitions[column_name]
          end

        define_method(column_name) do
          statuses.find { |status_name, status_num| instance_variable_get("@#{column_name}") == status_num }.first
        end

        status_names = statuses.keys

        status_names.each do |status_name|
          define_method("#{status_name}?") do
            instance_variable_get("@#{column_name}") == statuses[status_name]
          end

          define_method("#{status_name}!") do
            instance_variable_set("@#{column_name}", statuses[status_name])
          end

          define_singleton_method(status_name) do
            $database.select { |record| record.instance_variable_get("@#{column_name}") == statuses[status_name] }
          end

          define_singleton_method("not_#{status_name}") do
            $database.reject { |record| record.instance_variable_get("@#{column_name}") == statuses[status_name] }
          end
        end

        status_name_pairs = status_names.each_with_object({}) do |status_name, hash|
          hash[status_name] = status_names.dup.tap { |arr| arr.delete(status_name) }
        end

        status_name_pairs.each do |key, vals|
          vals.each do |val|
            define_singleton_method("#{key}_or_#{val}") do
              send(key) | send(val)
            end
          end
        end
      end
    end
  end
end
