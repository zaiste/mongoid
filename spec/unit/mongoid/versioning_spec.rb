require "spec_helper"

describe Mongoid::Versioning do

  describe ".max_versions" do

    context "when provided an integer" do

      before do
        WikiPage.max_versions(10)
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should == 10
      end
    end

    context "when provided a string" do

      before do
        WikiPage.max_versions("10")
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should == 10
      end
    end
  end

  describe "#revise" do

    context "when a last version does not exist" do

      let!(:page) do
        WikiPage.new(:title => "1")
      end

      before do
        WikiPage.expects(:first).with(
          :conditions => { :_id => page.id, :version => 1 }
        ).returns(nil)
        page.revise
      end

      it "does not add any versions" do
        page.versions.should be_empty
      end
    end

    context "when a last version exists" do

      let!(:page) do
        WikiPage.new(:title => "1", :version => 2)
      end

      let!(:first) do
        WikiPage.new(:title => "1", :version => 1)
      end

      before do
        WikiPage.expects(:first).with(
          :conditions => { :_id => page.id, :version => 2 }
        ).returns(first)
        page.revise
      end

      it "does not add any versions" do
        page.versions.size.should == 1
      end
    end

    context "when skipping versioning" do

      let(:person) do
        Person.new(:created_at => Time.now.utc)
      end

      before do
        person.new_record = false
      end

      it "does not add any versions" do
        person.expects(:revise).never
        person.versionless(&:save)
      end
    end
  end

  context "when the document has not changed" do

    let(:person) do
      Person.new(:created_at => Time.now.utc)
    end

    before do
      person.new_record = false
    end

    it "does not run the versioning callbacks" do
      person.expects(:revise).never
      person.save
    end
  end

  describe "#versionless" do

    let(:person) do
      Person.new(:created_at => Time.now.utc)
    end

    context "when executing the block" do

      it "sets versionless to true" do
        person.versionless do |doc|
          doc.should be_versionless
        end
      end
    end

    context "when the block finishes" do

      it "sets versionless to false" do
        person.versionless
        person.should_not be_versionless
      end
    end
  end
end
