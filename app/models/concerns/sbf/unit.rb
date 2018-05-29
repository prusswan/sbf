module SBF::Unit
  extend ActiveSupport::Concern

  included do
    belongs_to :block
    belongs_to :flat_block, foreign_key: :block_id, class_name: 'Block'
    belongs_to :quota

    # not intuitive, but this works better with rails_admin than delegate
    has_one :estate, through: :flat_block

    delegate :probable_date, :delivery_date, :lease_start, to: :flat_block

    default_scope { includes(:estate) }

    rails_admin do
      # Found associations:

      configure :estate, :has_one_association
      configure :block, :belongs_to_association
      configure :quota, :belongs_to_association

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
          pretty_value do
            bindings[:view].link_to bindings[:object].estate.name, bindings[:view].rails_admin.show_path(:estate, bindings[:object].estate)
          end
          enum do
            # ::Estate.all.map(&:name) #.uniq.to_a
            # estate_id = bindings[:object].estate.id
            ::Estate.all.map {|e| [e.name, e.id]}
          end
          sortable 'estates.name'
          # searchable 'estates.name'
          # searchable :estate
          # searchable [{:estate => :name }]
          searchable [{Block => :estate_id}]
          search_operator 'in'

          queryable :true

          column_width 50
        end
        field :flat_type, :enum do
          column_width 50
          enum do
            # ::Unit.distinct.pluck(:flat_type).sort
            ["2-Room Flexi (Short Lease)", "2-Room Flexi (Short Lease/99-Year Lease)",
              "3-Room", "3-Room (income ceiling $12,000)", "3-Room (income ceiling $6,000)",
              "4-Room", "5-Room", "5-Room/3Gen", "Executive"]
          end
          search_operator 'in'
        end
        field :block do
          pretty_value do
            bindings[:view].link_to "#{bindings[:object].block.no} #{bindings[:object].block.street}",
              bindings[:view].rails_admin.show_path(:block, bindings[:object].block)
          end
          sortable Block.sql_by_address
          searchable [:no, :street]
          queryable :true

          column_width 100
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

        # field :ethnic_quota do
        #   pretty_value { bindings[:object].block.short_ethnic_quota }
        #   sortable 'blocks.ethnic_quota'
        #   column_width 25
        # end

        field :quota do
          pretty_value { bindings[:object].quota.summary }
          column_width 50
        end
      end

      # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
      # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
      # using `field` instead of `configure` will exclude all other fields and force the ordering
    end
  end

  module ClassMethods
    def check_quotas
      bad_u = Unit.all.select {|u| u.flat_type != u.quota.flat_type }
    end

    def fix_quotas
      # Fix 1: update Unit.quota_id
      # bad_u.each {|u| u.quota_id = Quota.where(block_id: u.block_id, flat_type: u.flat_type).first.id; u.save }

      # Fix 2: redump Quota table
      SeedDump.dump(Estate, file: 'db/seeds.rb')
      SeedDump.dump(Block, file: 'db/seeds.rb', append: true)
      SeedDump.dump(Unit, file: 'db/seeds.rb', append: true)

      qs = Unit.all.map {|u| Quota.where(flat_type: u.flat_type, block_id: u.block_id).first }
      SeedDump.dump(qs.uniq, file: 'db/seeds.rb', append: true)
    end
  end
end
