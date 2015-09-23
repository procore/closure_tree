class Tag < ActiveRecord::Base
  has_closure_tree :dependent => :destroy, :order => :name
  before_destroy :add_destroyed_tag

  def to_s
    name
  end

  def add_destroyed_tag
    # Proof for the tests that the destroy rather than the delete method was called:
    DestroyedTag.create(:name => name)
  end
end

class UUIDTag < ActiveRecord::Base
  self.primary_key = :uuid
  before_create :set_uuid
  has_closure_tree dependent: :destroy, order: 'name', parent_column_name: 'parent_uuid'
  before_destroy :add_destroyed_tag

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def to_s
    name
  end

  def add_destroyed_tag
    # Proof for the tests that the destroy rather than the delete method was called:
    DestroyedTag.create(:name => name)
  end
end

class DestroyedTag < ActiveRecord::Base
end

class User < ActiveRecord::Base
  acts_as_tree :parent_column_name => "referrer_id",
    :name_column => 'email',
    :hierarchy_class_name => 'ReferralHierarchy',
    :hierarchy_table_name => 'referral_hierarchies'

  has_many :contracts

  def indirect_contracts
    Contract.where(:user_id => descendant_ids)
  end

  def to_s
    email
  end
end

class Contract < ActiveRecord::Base
  belongs_to :user
end

class Label < ActiveRecord::Base
  # make sure order doesn't matter
  acts_as_tree :order => :column_whereby_ordering_is_inferred, # <- symbol, and not "sort_order"
    :parent_column_name => "mother_id",
    :dependent => :destroy

  def to_s
    "#{self.class}: #{name}"
  end
end

class EventLabel < Label
end

class DateLabel < Label
end

class DirectoryLabel < Label
end

class CuisineType < ActiveRecord::Base
  acts_as_tree
end

module Namespace
  def self.table_name_prefix
    'namespace_'
  end
  class Type < ActiveRecord::Base
    has_closure_tree dependent: :destroy
  end
end

class Metal < ActiveRecord::Base
  self.table_name = "#{table_name_prefix}metal#{table_name_suffix}"
  has_closure_tree order: 'sort_order', name_column: 'value'
  self.inheritance_column = 'metal_type'
end

class Adamantium < Metal
end

class Unobtanium < Metal
end

class MenuItem < ActiveRecord::Base
  has_closure_tree touch: true, with_advisory_lock: false
end
