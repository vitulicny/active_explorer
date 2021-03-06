module ActiveExplorer
  class Painter
    def initialize(exploration, file_path)
      @exploration = exploration
      @file_path = file_path
      @graph = GraphViz.new(:G, :type => :digraph)
    end

    def paint(origin_as_root: false)
      @centralized = origin_as_root
      paint_object @exploration.get_hash, @graph, nil
      save_to_file
      @graph
    end

    private

    def paint_object(hash, graph, parent_node)
      style = parent_node.nil? ? :origin : nil

      node = add_node(hash, graph, style: style)
      add_edge(graph, parent_node, node, hash[:association]) unless parent_node.nil?

      paint_subobjects graph, node, hash[:subobjects] unless hash[:subobjects].nil?
    end

    def paint_subobjects(graph, parent_node, subhashes)
      subhashes.each do |hash|
        paint_object hash, graph, parent_node
      end
    end

    def add_node(hash, graph, style: nil)
      id = hash[:attributes][:id]
      class_name = make_safe(hash[:class_name])
      attributes = make_safe(hash[:attributes].keys.join("\n"))
      values = hash[:attributes].values.collect do |val|
        if val.nil?
          'nil'
        elsif val.is_a? String
          "\"#{make_short(val)}\""
        else
          make_short(val.to_s)
        end
      end
      values = make_safe(values.join("\n"))

      if style == :origin
        graph.add_node("#{class_name}_#{id}", shape: "record", label: "{#{class_name}|{#{attributes}|#{values}}}", labelloc: 't', style: 'filled', fillcolor: 'yellow')
      else
        graph.add_node("#{class_name}_#{id}", shape: "record", label: "{#{class_name}|{#{attributes}|#{values}}}", labelloc: 't')
      end
    end

    def add_edge(graph, parent_node, node, association)
      if @centralized
        graph.add_edge(parent_node, node, label: association == :belongs_to ? ' belongs to' : ' has') unless edge_exists?(graph, parent_node, node)
      else
        if association == :belongs_to
          graph.add_edge(node, parent_node) unless edge_exists?(graph, node, parent_node)
        else
          graph.add_edge(parent_node, node) unless edge_exists?(graph, parent_node, node)
        end
      end
    end

    def edge_exists?(graph, node_one, node_two)
      graph.each_edge do |edge|
        return true if edge.node_one == node_one.id && edge.node_two == node_two.id
      end

      false
    end

    def save_to_file
      filename = @file_path.split(File::SEPARATOR).last
      directory = @file_path.chomp filename

      create_directory directory unless directory.empty?

      @graph.output(:png => @file_path)
    end

    def create_directory(directory)
      unless directory.empty? || File.directory?(directory)
        FileUtils.mkdir_p directory
      end
    end

    def make_short(text)
      text.length < 70 ? text : text[0..70] + " (...)"
    end

    # Replace characters that conflict with DOT language (used in GraphViz).
    # These: `{`, `}`, `<`, `>`, `|`, `\`
    #
    def make_safe(text)
      text.tr('{}<>|\\', '')
    end
  end
end