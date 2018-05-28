module SBF::Quora
  extend ActiveSupport::Concern

  included do
    belongs_to :block
    has_many :units

    has_one :estate, through: :block

    # Warning: default_scope + join breaks update of records: https://github.com/rails/rails/issues/11199
    default_scope { joins(:estate).readonly(false) }

    # attr_accessible :malay, :chinese, :others

    # include ActiveModel::ForbiddenAttributesProtection

    rails_admin do
      object_label_method :full_summary

      list do
        filters [:estate, :flat_type]
        # sort_by :estate

        field :estate, :enum do
          pretty_value do
            bindings[:view].link_to bindings[:object].estate.name, bindings[:view].rails_admin.show_path(:estate, bindings[:object].estate)
          end
          enum do
            Estate.all.map(&:name).uniq.to_a
          end
          sortable "estates.name, flat_type, #{Block.sql_by_address}"
          searchable 'estates.name'
          queryable :true

          column_width 50
        end
        field :flat_type do
          pretty_value do
            block_id = bindings[:object].block_id
            unit_count = Unit.where(block_id: block_id, flat_type: bindings[:object].flat_type).count
            "#{bindings[:object].flat_type} (#{unit_count})"
          end
          column_width 50
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

        field :malay do
          column_width 50
        end
        field :chinese do
          column_width 50
        end
        field :others do
          column_width 50
        end
      end

      # edit do
      #   field :malay
      #   field :chinese
      #   field :others
      # end
    end
  end

  def summary
    "M:#{malay},C:#{chinese},I/O:#{others}"
  end

  def full_summary
    "(#{flat_type}) #{summary}"
  end

end
