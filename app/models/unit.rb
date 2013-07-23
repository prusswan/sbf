class Unit < ActiveRecord::Base
  belongs_to :block
  belongs_to :flat_block, foreign_key: :block_id, class_name: 'Block'

  # not intuitive, but this works better with rails_admin than delegate
  has_one :estate, through: :flat_block

  delegate :probable_date, :delivery_date, :lease_start, to: :flat_block

  default_scope { joins(:estate) }

  rails_admin do
    # Found associations:

    configure :estate, :has_one_association
    configure :block, :belongs_to_association

    # Found columns:

    # configure :id, :integer
    configure :no, :string
    configure :price, :integer
    configure :area, :integer
    configure :flat_type, :string
    # configure :block_id, :integer         # Hidden
    configure :created_at, :datetime
    configure :updated_at, :datetime

    configure :probable_date, :string
    configure :delivery_date, :string
    configure :lease_start, :string

    # Cross-section configuration:

    object_label_method :no         # Name of the method called for pretty printing an *instance* of ModelName
    # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
    # label_plural 'My models'      # Same, plural
    weight 2                        # Navigation priority. Bigger is higher.
    # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
    # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

    # Section specific configuration:

    list do
      filters [:estate, :flat_type, :price, :area]  # Array of field names which filters should be shown by default in the table header
      # items_per_page 100    # Override default_items_per_page
      sort_by "flat_type desc, price" # Sort column (default is primary key)
      sort_reverse false              # Sort direction (default is true for primary key, last created first)

      field :estate, :enum do
        pretty_value { bindings[:object].estate.name }
        enum do
          Estate.all.map(&:name).uniq.to_a
        end
        sortable 'estates.name'
        searchable 'estates.name'
        queryable :true

        column_width 50
      end
      field :flat_type do
        column_width 50
      end
      field :block do
        pretty_value { "#{bindings[:object].block.no} #{bindings[:object].block.street}" }
        sortable 'estates.name'
        searchable [:no, :street]
        queryable :true

        column_width 150
      end
      field :no do
        column_width 50
      end
      field :price do
        column_width 50
      end
      field :area do
       column_width 10
      end

      field :probable_date do
        pretty_value { bindings[:object].block.probable_date }
        sortable 'blocks.probable_date'
        column_width 50
      end
      field :delivery_date do
        pretty_value { bindings[:object].block.delivery_date }
        sortable Block.sql_by_delivery_date
        column_width 50
      end
      field :lease_start do
        pretty_value { bindings[:object].block.lease_start }
        sortable Block.sql_by_lease_start
        column_width 50
      end
    end

    # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
    # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
    # using `field` instead of `configure` will exclude all other fields and force the ordering
  end
end
