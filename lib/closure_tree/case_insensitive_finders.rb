module ClosureTree
  module CaseInsensitiveFinders
    extend ActiveSupport::Concern
    include Finders

    def find_or_create_by_path(path, attributes = {})
      subpath = _ct.build_ancestry_attr_path(path, attributes)
      return self if subpath.empty?

      found = find_by_path(subpath, attributes)
      return found if found

      split_subpath        = self.class.demerge_attrs(subpath)
      attrs                = subpath.shift
      name_hash, rest_hash = split_subpath.shift
      name                 = name_hash[_ct.name_column].downcase

      _ct.with_advisory_lock do
        # shenanigans because children.create is bound to the superclass
        # (in the case of polymorphism):

        found_child = self.children
          .where(self.class.lowered_name_column_clause, name)
          .where(rest_hash)
          .first

        child = found_child || begin
          # Support STI creation by using base_class:
          _ct.create(self.class, attrs).tap do |ea|
            # We know that there isn't a cycle, because we just created it, and
            # cycle detection is expensive when the node is deep.
            ea._ct_skip_cycle_detection!
            self.children << ea
          end
        end
        child.find_or_create_by_path(subpath, attributes)
      end
    end

    module ClassMethods
      # Find the node whose +ancestry_path+ is +path+
      def find_by_path(path, attributes = {}, parent_id = nil)
        path = _ct.build_ancestry_attr_path(path, attributes)

        if path.size > _ct.max_join_tables
          return _ct.find_by_large_path(path, attributes, parent_id)
        end

        path                 = demerge_attrs(path)
        name_hash, rest_hash = path.pop
        name                 = name_hash[_ct.name_column].downcase

        scope = where(
          lowered_name_column_clause, name
        ).where(rest_hash)

        last_joined_table = _ct.table_name
        path.reverse.each_with_index do |ea, idx|
          next_joined_table    = "p#{idx}"
          name_hash, rest_hash = ea
          name                 = name_hash[_ct.name_column].downcase

          scope = scope.joins(<<-SQL.strip_heredoc)
              INNER JOIN #{_ct.quoted_table_name} AS #{next_joined_table}
                ON #{next_joined_table}.#{_ct.quoted_id_column_name} =
          #{connection.quote_table_name(last_joined_table)}.#{_ct.quoted_parent_column_name}
          SQL

          scope = scope.where(
            "LOWER(#{next_joined_table}.#{_ct.quoted_name_column}) = ?",
            name
          )

          scope = _ct.scoped_attributes(scope, rest_hash, next_joined_table)
          last_joined_table = next_joined_table
        end

        scope.where("#{last_joined_table}.#{_ct.parent_column_name}" => parent_id).readonly(false).first
      end

      # Find or create nodes such that the +ancestry_path+ is +path+
      def find_or_create_by_path(path, attributes = {})
        attr_path = _ct.build_ancestry_attr_path(path, attributes)
        find_by_path(attr_path) || begin
          split_attr_path      = demerge_attrs(attr_path)
          root_attrs           = attr_path.shift
          name_hash, rest_hash = split_attr_path.shift
          name                 = name_hash[_ct.name_column].downcase

          _ct.with_advisory_lock do
            # shenanigans because find_or_create can't infer that we want the same class as this:
            # Note that roots will already be constrained to this subclass (in the case of polymorphism):

            found_root =
              roots
                .where(lowered_name_column_clause, name)
                .where(rest_hash)
                .first

            root = found_root || _ct.create!(self, root_attrs)

            root.find_or_create_by_path(attr_path)
          end
        end
      end

      def demerge_attrs(path)
        path
          .map(&:with_indifferent_access)
          .map { |ea| [ea.slice(_ct.name_column), ea.except(_ct.name_column)] }
      end

      def lowered_name_column_clause
        "LOWER(#{_ct.quoted_table_name}.#{_ct.quoted_name_column}) = ?"
      end
    end
  end
end
