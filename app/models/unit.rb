class Unit < ActiveRecord::Base
  belongs_to :block

  rails_admin do
    # Found associations:

    configure :block, :belongs_to_association

    # Found columns:

    configure :id, :integer
    configure :no, :string
    configure :price, :string
    configure :area, :string
    configure :flat_type, :string
    configure :block_id, :integer         # Hidden
    configure :created_at, :datetime
    configure :updated_at, :datetime

    # Cross-section configuration:

    object_label_method :no         # Name of the method called for pretty printing an *instance* of ModelName
    # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
    # label_plural 'My models'      # Same, plural
    weight 2                        # Navigation priority. Bigger is higher.
    # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
    # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

    # Section specific configuration:

    list do
      filters [:no, :price, :area]  # Array of field names which filters should be shown by default in the table header
      # items_per_page 100    # Override default_items_per_page
      # sort_by :id           # Sort column (default is primary key)
      # sort_reverse true     # Sort direction (default is true for primary key, last created first)

      field :flat_type
      field :block do
        pretty_value do
          "#{bindings[:object].block.no} #{bindings[:object].block.street}"
        end
      end
      field :no
      field :price
      field :area

      field :probable_date do
        pretty_value do
          bindings[:object].block.probable_date
        end
      end
      field :delivery_date do
        pretty_value do
          bindings[:object].block.delivery_date
        end
      end
      field :lease_start do
        pretty_value do
          bindings[:object].block.lease_start
        end
      end
    end

    # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
    # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
    # using `field` instead of `configure` will exclude all other fields and force the ordering
  end
end
