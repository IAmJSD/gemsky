class BaseModel
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::API
    extend ActiveModel::Callbacks

    def self.schema(schema_object)
        schema_object.each do |k, v|
            attribute k, v
        end
    end

    def self.validates_many(items, *args, **kwargs)
        items.each do |item|
            validates item, *args, **kwargs
        end
    end
end
