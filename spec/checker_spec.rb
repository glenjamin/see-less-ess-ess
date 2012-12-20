require File.expand_path('../../lib/see-less-ess-ess.rb', __FILE__)

module SeeLessEssEss
  describe "Checker" do
    let(:extractor) do
      mock("Extractor").tap do |m|
        m.stub!(:css_classes).and_return(parsed_css_classes)
      end
    end
    let(:parsed_css_classes) { %w(row columns one two top-bar) }
    let(:used_css_classes) { %w(zebra) }

    let(:subject) { Checker.new(extractor, used_css_classes) }

    describe "does_not_use" do

      it "should keep .row" do
        subject.does_not_use(
          sequence(simple_sequence(className('row')))
        ).should be_false
      end
      it "should keep body.row" do
        subject.does_not_use(
          sequence(simple_sequence(tag('body'), className('row')))
        ).should be_false
      end
      it "should keep .zebra td" do
        subject.does_not_use(
          sequence(
            simple_sequence(className('zebra')),
            simple_sequence(tag('td'))
          )
        ).should be_false
      end
      it "should keep body" do
        subject.does_not_use(
          sequence(simple_sequence(tag('body')))
        ).should be_false
      end
      it "should keep #id" do
        subject.does_not_use(
          sequence(simple_sequence(id('id')))
        ).should be_false
      end

      it "should reject .class" do
        subject.does_not_use(
          sequence(simple_sequence(className('class')))
        ).should be_true
      end
      it "should reject .row .class" do
        subject.does_not_use(
          sequence(
            simple_sequence(className('row')),
            simple_sequence(className('class'))
          )
        ).should be_true
      end

      def sequence(*args)
        Sass::Selector::Sequence.new(args)
      end
      def simple_sequence(*args)
        Sass::Selector::SimpleSequence.new(args, false)
      end
      def className(name)
        Sass::Selector::Class.new([name])
      end
      def tag(name)
        Sass::Selector::Element.new([name], nil)
      end
      def id(id)
        Sass::Selector::Id.new([id])
      end

    end
  end
end
