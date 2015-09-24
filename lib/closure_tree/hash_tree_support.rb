module ClosureTree
  module HashTreeSupport
    def default_tree_scope(limit_depth = nil)
        # Deepest generation, within limit, for each descendant
        # NOTE: Postgres requires HAVING clauses to always contains aggregate functions (!!)
        having_clause = limit_depth ? "HAVING MAX(generations) <= #{limit_depth - 1}" : ''
        generation_depth = <<-SQL.strip_heredoc
          INNER JOIN (
            SELECT descendant_id, MAX(generations) as depth
            FROM #{quoted_hierarchy_table_name}
            INNER JOIN (#{model_class.all.to_sql}) AS outer_table
              ON outer_table.#{model_class.primary_key} = #{quoted_hierarchy_table_name}.descendant_id
            GROUP BY descendant_id
            #{having_clause}
          ) AS generation_depth
            ON #{quoted_table_name}.#{model_class.primary_key} = generation_depth.descendant_id
        SQL
        scope_with_order(model_class.joins(generation_depth), 'generation_depth.depth')
      end

    def hash_tree(tree_scope, limit_depth = nil)
      limited_scope = if tree_scope
        limit_depth ? tree_scope.where("#{quoted_hierarchy_table_name}.generations <= #{limit_depth - 1}") : tree_scope
      else
        default_tree_scope(limit_depth)
      end
      build_hash_tree(limited_scope)
    end

    # Builds nested hash structure using the scope returned from the passed in scope
    def build_hash_tree(tree_scope)
      tree = ActiveSupport::OrderedHash.new
      id_to_hash = {}

      tree_scope.each do |ea|
        h = id_to_hash[ea.id] = ActiveSupport::OrderedHash.new
        (id_to_hash[ea._ct_parent_id] || tree)[ea] = h
      end
      tree
    end
  end
end