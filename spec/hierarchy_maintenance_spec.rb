require 'spec_helper'

describe ClosureTree::HierarchyMaintenance do
  describe '.rebuild!' do
    it 'rebuild tree' do
      20.times do |counter|
        Metal.create(:value => "Nitro-#{counter}", parent: Metal.all.sample)
      end
      hierarchy_count = MetalHierarchy.count
      expect(hierarchy_count).to be > (20*2)-1 # shallowest-possible case, where all children use the first root
      Metal.roots.each do |n|
        n.delete_hierarchy_references # delete hierarchies scoped to the caller
        n.send(:rebuild!) # roots just uses the parent_id column, so this is safe.
      end
      expect(MetalHierarchy.count).to eq(hierarchy_count)
    end
  end
end
