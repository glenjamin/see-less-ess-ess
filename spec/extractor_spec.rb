require File.expand_path('../../lib/see-less-ess-ess.rb', __FILE__)

module SeeLessEssEss
  describe "Extractor" do

    let(:subject) { Extractor.new(location) }
    let(:location) { File.expand_path('../fixtures', __FILE__) }

    it "should read all css classes from html files in location" do
      subject.css_classes.should include(*%w(body1 body2 title main left lead))
    end

  end
end
