module ClosureTree
  module CaseInsensitiveFinders
    extend ActiveSupport::Concern
    include Finders

    module ClassMethods

      # Find the node whose +ancestry_path+ is +path+
      def find_by_path(path, attributes = {}, parent_id = nil)
        path = _ct.build_ancestry_attr_path(path, attributes)

        if path.size > _ct.max_join_tables
          return _ct.find_by_large_path(path, attributes, parent_id)
        end

        path = path
          .map(&:with_indifferent_access)
          .map { |ea| [ea[_ct.name_column].downcase, ea.except(_ct.name_column)] }

        first_name, first_attributes = path.pop

        scope = where(
          "LOWER(#{_ct.quoted_table_name}.#{_ct.quoted_name_column}) = ?",
          first_name
        ).where(first_attributes)

        last_joined_table = _ct.table_name
        path.reverse.each_with_index do |ea, idx|
          next_joined_table = "p#{idx}"
          name, attrs = ea
          scope = scope.joins(<<-SQL.strip_heredoc)
              INNER JOIN #{_ct.quoted_table_name} AS #{next_joined_table}
                ON #{next_joined_table}.#{_ct.quoted_id_column_name} =
          #{connection.quote_table_name(last_joined_table)}.#{_ct.quoted_parent_column_name}
          SQL

          scope = scope.where(
            "LOWER(#{next_joined_table}.#{_ct.quoted_name_column}) = ?",
            name
          )

          scope = _ct.scoped_attributes(scope, attrs, next_joined_table)
          last_joined_table = next_joined_table
        end

        scope.where("#{last_joined_table}.#{_ct.parent_column_name}" => parent_id).readonly(false).first
      end
    end
  end
end
