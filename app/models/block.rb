class Block < ActiveRecord::Base
  has_many :units, -> { order(:no) }

  belongs_to :estate

  class << self
    def sort_by_delivery_date(collection=self.all)
      collection.sort { |a,b| compare_delivery_date(a,b) }
    end

    def compare_delivery_date(a,b)
      begin
        date_a = a.delivery_date.to_date
      rescue
        date_a = Date.new
      end

      begin
        date_b = b.delivery_date.to_date
      rescue
        date_b = Date.new
      end

      date_a <=> date_b
    end

    def sql_by_delivery_date
      case ActiveRecord::Base.connection.instance_values["config"][:adapter].to_sym
      when :mysql2
        'str_to_date(blocks.delivery_date, \'%d %M %Y\'), str_to_date(blocks.lease_start, \'%d %M %Y\')'
      when :postgresql
        'to_date(blocks.delivery_date, \'DD Mon YYYY\'), to_date(blocks.lease_start, \'DD Mon YYYY\')'
      end
    end

    def sql_by_lease_start
      case ActiveRecord::Base.connection.instance_values["config"][:adapter].to_sym
      when :mysql2
        'str_to_date(blocks.lease_start, \'%d %M %Y\')'
      when :postgresql
        'to_date(blocks.lease_start, \'DD Mon YYYY\')'
      end
    end
  end

  rails_admin do
    # Found associations:

    configure :estate, :belongs_to_association
    configure :units, :has_many_association

    # Found columns:

    configure :id, :integer
    configure :no, :string
    configure :street, :string
    configure :probable_date, :string
    configure :delivery_date, :string
    configure :lease_start, :string
    configure :ethnic_quota, :string
    configure :created_at, :datetime
    configure :updated_at, :datetime
    configure :estate_id, :integer         # Hidden

    # Cross-section configuration:

    object_label_method :no         # Name of the method called for pretty printing an *instance* of ModelName
    # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
    # label_plural 'My models'      # Same, plural
    weight 1                        # Navigation priority. Bigger is higher.
    # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
    # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

    # Section specific configuration:

    list do
      # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
      # items_per_page 100    # Override default_items_per_page
      # sort_by :id           # Sort column (default is primary key)
      # sort_reverse true     # Sort direction (default is true for primary key, last created first)

      field :estate
      field :no
      field :street
      field :probable_date do
        column_width 100
      end
      field :delivery_date do
        column_width 100
        sortable Block.sql_by_delivery_date
      end
      field :lease_start do
        column_width 100
        sortable Block.sql_by_lease_start
      end
      field :ethnic_quota
    end

    # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
    # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
    # using `field` instead of `configure` will exclude all other fields and force the ordering
  end
end
