require 'spec_helper'
require 'tag_examples'

describe CaseInsensitiveTag do
  it_behaves_like Tag

  context 'with 1 tag' do
    before do
      @name = "Tag"
      @tag = described_class.create!(name: @name)
    end

    it "finds by path" do
      found_tag = described_class.find_by_path([@name])

      expect(found_tag).to eq(@tag)
    end

    it "finds by path upcased" do
      found_tag = described_class.find_by_path([@name.upcase])

      expect(found_tag).to eq(@tag)
    end

    it "finds by path through find_or_create_by_path" do
      found_tag = described_class.find_or_create_by_path([@name])

      expect(found_tag).to eq(@tag)
    end

    it "finds by path upcased through find_or_create_by_path" do
      found_tag = described_class.find_or_create_by_path([@name.upcase])

      expect(found_tag).to eq(@tag)
    end

    it "creates a new tag by path" do
      new_tag = described_class.find_or_create_by_path([@name, "Child Tag"])

      expect(new_tag.parent).to eq @tag
      expect(new_tag.name).to eq "Child Tag"
    end

    it "creates a new tag by path with upcased parent name" do
      new_tag = described_class.find_or_create_by_path([@name.upcase, "Child Tag"])

      expect(new_tag.parent).to eq @tag
      expect(new_tag.name).to eq "Child Tag"
    end
  end

  context 'with 2 tags' do
    before do
      @parent_name = "Tag"
      @parent_tag = described_class.create!(name: @parent_name)

      @child_name = "Child Tag"
      @child_tag = described_class.create!(name: @child_name, parent: @parent_tag)
    end

    it "finds by path" do
      found_tag = described_class.find_by_path([@parent_name, @child_name])

      expect(found_tag).to eq(@child_tag)
    end

    it "finds by path upcased" do
      found_tag = described_class.find_by_path(
        [@parent_name, @child_name].map(&:upcase)
      )

      expect(found_tag).to eq(@child_tag)
    end

    it "finds by path through find_or_create_by_path" do
      found_tag = described_class.find_or_create_by_path([@parent_name, @child_name])

      expect(found_tag).to eq(@child_tag)
    end

    it "finds by path upcased through find_or_create_by_path" do
      found_tag = described_class.find_or_create_by_path(
        [@parent_name, @child_name].map(&:upcase)
      )

      expect(found_tag).to eq(@child_tag)
    end

    it "creates a new tag by path" do
      new_tag = described_class.find_or_create_by_path(
        [@parent_name, @child_name, "Grandchild Tag"]
      )

      expect(new_tag.parent).to eq @child_tag
      expect(new_tag.name).to eq "Grandchild Tag"
    end

    it "creates a new tag by path with different cased names" do
      new_tag = described_class.find_or_create_by_path(
        [@parent_name.downcase, @child_name.upcase, "Grandchild Tag"]
      )

      expect(new_tag.parent).to eq @child_tag
      expect(new_tag.name).to eq "Grandchild Tag"
    end
  end
end
