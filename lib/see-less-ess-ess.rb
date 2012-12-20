module SeeLessEssEss
  VERSION = '0.0.1'

  class Checker
    def self.create
      return new
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
        css_classes_blacklist.include?(simple.name[0].to_s)
      else
        false
      end
    end

    def css_classes_blacklist
      %w(top-bar row columns)
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
end

Compass::Configuration.add_configuration_property(
  :templates_location, "Directory to scan for template files") do

  project_path
end

class Sass::Engine
  alias_method :_slss_to_tree, :_to_tree
  def _to_tree
    checker = SeeLessEssEss::Checker.create

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
