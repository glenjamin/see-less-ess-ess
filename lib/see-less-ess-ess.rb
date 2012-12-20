module SeeLessEssEss
  VERSION = '0.0.1'

  class RemoveUnusedRules < Sass::Tree::Visitors::Base

    # @param root [Tree::Node] The root node of the tree to visit.
    # @return [(Tree::Node, Sass::Util::SubsetMap)] The resulting tree of static nodes
    # *and* the extensions defined for this tree
    def self.visit(root); super; end

    # If an exception is raised, this adds proper metadata to the backtrace.
    def visit(node)
      super(node)
    rescue Sass::SyntaxError => e
      e.modify_backtrace(:filename => node.filename, :line => node.line)
      raise e
    end

    def remove_unused(node)
      yield
      node.children.reject! do |child|
        unused_node?(child)
      end
    end

    alias :visit_root :remove_unused
    alias :visit_media :remove_unused

    def unused_node?(node)
      if node.invisible?
        return false
      end
      if node.respond_to? :resolved_rules
        node.resolved_rules.members.reject! do |s|
          selector = s.to_a.join.strip
          unused_selector?(selector)
        end
      end
      false
    end

    def unused_selector?(selector)
      selector =~ /^.top-bar/
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
    tree = _slss_to_tree
    if @options[:filename] == @options[:original_filename]
      meta = class << tree; self; end
      meta.send(:define_method, :render) {
        Sass::Tree::Visitors::CheckNesting.visit(self)
        result = Sass::Tree::Visitors::Perform.visit(self)
        # Check again to validate mixins
        Sass::Tree::Visitors::CheckNesting.visit(result)
        result, extends = Sass::Tree::Visitors::Cssize.visit(result)
        Sass::Tree::Visitors::Extend.visit(result, extends)
        SeeLessEssEss::RemoveUnusedRules.visit(result)
        result.to_s
      }
    end
    tree
  end
end
