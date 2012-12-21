require 'set'

require 'sass'
require 'nokogiri'

module SeeLessEssEss
  VERSION = '0.0.2'

  class Extractor
    def initialize(glob)
      @glob = glob
      @extracted = false
    end

    def css_classes
      extract_if_needed
      @css_classes
    end
    def html_tags
      extract_if_needed
      @html_tags
    end

    protected

    def files
      Dir.glob(@glob)
    end
    def extract_if_needed
      collector = Collector.new()
      files.each do |file|
        parser = Nokogiri::HTML::SAX::Parser.new(collector)
        parser.parse(open(file, 'rb').read)
      end
      @css_classes = collector.css_classes
      @html_tags = collector.html_tags
    end

    class Collector < Nokogiri::XML::SAX::Document
      def css_classes
        @css_classes ||= Set.new
      end
      def html_tags
        @html_tags ||= Set.new
      end
      def start_element(tag, attrs = [])
        html_tags << tag
        attrs.each do |name, value|
          if name == "class"
            css_classes.merge(value.split)
          end
        end
      end
    end
  end

  class Checker

    def initialize(extractor, used_classes)
      @extractor = extractor
      @used_classes = used_classes
    end

    def does_not_use(sequence)
      selectors = sequence.members.reject { |s| s.is_a?(String) }
      selectors.any? do |selector|
        selector.members.any? do |simple|
          unused(simple)
        end
      end
    end

    def unused(simple)
      if simple.is_a?(Sass::Selector::Class)
        !css_classes_whitelist.include?(simple.name[0].to_s)
      elsif simple.is_a?(Sass::Selector::Element)
        !html_tags_whitelist.include?(simple.name[0].to_s)
      else
        false
      end
    end

    def css_classes_whitelist
      @class_whitelist ||= @extractor.css_classes + @used_classes
    end
    def html_tags_whitelist
      @tag_whitelist ||= @extractor.html_tags
    end
  end

  class RemoveUnusedRules < Sass::Tree::Visitors::Base

    def initialize(checker)
      @checker = checker
    end

    # If an exception is raised, this adds proper metadata to the backtrace.
    def visit(node)
      super(node)
    rescue Sass::SyntaxError => e
      e.modify_backtrace(:filename => node.filename, :line => node.line)
      raise e
    end

    def remove_unused_children(node)
      # Strip out any unused rules
      node.children.reject! do |child|
        if child.invisible?
          # Already wont be shown
          false
        elsif not child.respond_to? :resolved_rules
          # Only mess with RuleNodes
          false
        else
          child.resolved_rules.members.reject! do |sequence|
            @checker.does_not_use(sequence)
          end

          # Remove if there's nothing left
          child.resolved_rules.members.empty?
        end
      end

      yield
    end

    def visit_root(node, &block)
      remove_unused_children(node, &block)
    end
    def visit_media(node, &block)
      remove_unused_children(node, &block)
    end

  end

  def self.initialised?
    @@initialised ||= false
  end
  def self.init
    if not defined? ::Compass or initialised?
      return
    end
    @@initialised = true

    Compass::Configuration.add_configuration_property(
      :templates_glob, "Glob to scan for template files") do

      "#{project_path}/**/*.html"
    end
    Compass::Configuration.add_configuration_property(
      :used_css_classes, "CSS classes to explicity declare as 'used'") do

      []
    end

    Sass::Engine.class_eval do
      alias_method :_slss_to_tree, :_to_tree
      def _to_tree
        conf = Compass.configuration
        extractor = SeeLessEssEss::Extractor.new(conf.templates_glob)
        checker = SeeLessEssEss::Checker.new(extractor, conf.used_css_classes)

        tree = _slss_to_tree
        if @options[:filename] == @options[:original_filename]
          meta = class << tree; self; end
          meta.send(:define_method, :render) do
            # Taken verbatim from real #render
            Sass::Tree::Visitors::CheckNesting.visit(self)
            result = Sass::Tree::Visitors::Perform.visit(self)
            # Check again to validate mixins
            Sass::Tree::Visitors::CheckNesting.visit(result)
            result, extends = Sass::Tree::Visitors::Cssize.visit(result)
            Sass::Tree::Visitors::Extend.visit(result, extends)
            # The next line is our modification
            SeeLessEssEss::RemoveUnusedRules.new(checker).visit(result)
            result.to_s
          end
        end
        tree
      end
    end

  end
end

SeeLessEssEss.init
