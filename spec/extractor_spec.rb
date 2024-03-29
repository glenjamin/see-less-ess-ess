require File.expand_path('../../lib/see-less-ess-ess.rb', __FILE__)

module SeeLessEssEss
  describe "Extractor" do

    let(:subject) { Extractor.new(glob) }
    let(:glob) { "#{File.expand_path('../fixtures', __FILE__)}/**/*.html" }

    it "should read all css classes from html files in location" do
      subject.should have(6).css_classes
      subject.css_classes.should include(*%w(body1 body2 title main left lead))
    end

    it "should read all tags from html files in location" do
      subject.should have(6).html_tags
      subject.html_tags.should include(*%w(html head title body h1 p))
    end

  end
end
