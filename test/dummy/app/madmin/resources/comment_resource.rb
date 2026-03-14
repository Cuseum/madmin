class CommentResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Form sections (defined at class level, without a form block)
  section :content do
    attribute :body
  end

  section :associations, label: "Associations" do
    attribute :user
    attribute :commentable, collection: -> { Post.all }
  end

  # Uncomment this to customize the display name of records in the admin area.
  # def self.display_name(record)
  #   record.name
  # end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
