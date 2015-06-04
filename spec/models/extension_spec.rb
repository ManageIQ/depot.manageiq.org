require 'spec_helper'

describe Extension do
  describe "GitHub URL handling" do
    before do
      @e = Extension.new(github_url: "www.github.com/cvincent/test")
      @e.valid?
    end

    it "normalizes the URL before validation" do
      expect(@e.github_url).to eq("https://github.com/cvincent/test")
    end

    it "can return the username/repo formatted repo name from the URL" do
      expect(@e.github_repo).to eq("cvincent/test")
    end
  end
end
