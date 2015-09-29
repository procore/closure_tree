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
  end
end
