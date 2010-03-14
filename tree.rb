#!/usr/bin/ruby -w

# VERSION Wed Mar 10 11:04:54 CET 2010

# TODO:
# * Add support for polytomy
# * Add other traversal strategies (inorder, postorder, level)
class Tree

  def initialize(lineage, polytomy=false)
    @nodes = Hash.new
    @polytomy = polytomy
    @sep = "\t" # separator in to_lineage // to_s
    @traversal_strategy = 'pre'
    @current_node = nil
    @root_node = nil
    @visited = Hash.new
    parse(lineage)
  end

  attr_reader :polytomy, :root_node
  attr_accessor :sep

  # return string representation
  def to_s
  end

  # return subtree with current node
  # as root, a passed node as root
	# or nil if node is child
  def prune(node_name=@cnode.name)

  end

  # prune in place
  def prune!(node_name)
    
  end

  def visited?(node)
    @visited.has_key?(node.name)
  end

  def has_nodes?
   @visited.keys.size < @nodes.keys.size ? true : false
  end

  def node_exists?(node_name)
    @nodes.has_key?(node_name)
  end

  def add_node(name)
    node = Node.new(name)
    @nodes[name] = node
    return node
  end

  def set_traversal_strategy(s="pre")
    raise "*** E: only preoder traversal (pre) currently supported" unless (s == "pre")
    @traversal_strategy = s
  end

  def get_node(node_name)
    raise "*** E: Attempt to access undefined node #{node_name}" unless (self.node_exists?(node_name))
    @nodes[node_name]
  end

  def get_child_nodes(node_name)
    raise "*** E: Attempt to access undefined node #{node_name}" unless (self.node_exists?(node_name))
    @nodes[node_name].children
  end

  def get_parent_node(node_name)
    raise "*** E: Attempt to access undefined node #{node_name}" unless (self.node_exists?(node_name))
    @nodes[node_name].parent
  end

  # reset current_node to root
  def reset
		@visited = Hash.new
    @cnode = @root_node
		return
  end

	# wrapper for next_node
	# returns array of nodes in
	# current traverse_strategy
  # order
	def traverse
		a = Array.new
		while(self.has_nodes?) do a << self.next_node end
		return a
	end	

  # return next node given the
  # traversal strategy
  def next_node
    node = @cnode
    @visited[node.name] = 0
    pre_traversal(node)
    return node
  end

  def pre_traversal(node)
		return nil if @visited.keys.length == @nodes.keys.length
    if node.is_leaf?
			unless (self.visited?(node))
				@cnode = node
				return
			end
    else
			unless (self.visited?(node.left_child))
				@cnode = node.left_child
				return
			end			
			unless (self.visited?(node.right_child))
				@cnode = node.right_child
				return
			end			
    end
		pre_traversal(node.parent)
  end

  # returns lineage for species
  def to_lineage(species)

  end

  # returns tree object that represents
  # the subtree from this node onward
  def get_subtree(node)

  end

  private

  # parse lineage file
  def parse(lineage)
    begin
      f = File.open(lineage)
    rescue
      STDERR.puts "*** E: Cannot open / read file :#{lineage}"
      exit(1)
    end

    while (line = f.gets)
      next if (/^#.+/.match(line))
      next if (/^\s+/.match(line))
      line.chomp!
      l_nodes = line.split('; ')
      pnode = nil
      l_nodes.each do |n|
        node = self.node_exists?(n) ? @nodes[n] : self.add_node(n)
        if (not pnode.nil?)
          node.add_parent_node(pnode)
          pnode.add_child_node(node)
        else
          @root_node = node
        end
        pnode = node
      end
    end
     f.close
     @cnode = @root_node
  end

end

class Node

  def initialize(name)
    @name = name
    @parent = nil
    @children = Array.new
    @associations = Hash.new
  end

  attr_reader :name, :parent, :children, :associations

  def add_child_node(child_node)
    @children << child_node unless (@children.include?(child_node))
  end

  def add_parent_node(parent_node)
    @parent = parent_node
  end

  def has_children?
    not @children.nil?
  end

  def is_leaf?
    @children.empty? ? true : false
  end

  def is_root?
    @parent.nil? ? true : false
  end

  def left_child
    return nil if self.is_leaf?
    self.children[0]
  end

  def right_child
    return nil if self.is_leaf?
    self.children[1]
  end

  # associate object with node
  def assoc_with_node(name, reference)
		@associations[name] = reference
  end

  # return sister taxa, 
  # or root of neighbouring subtree
  # or nil if self is root node
  def get_sibling
    return nil if self.is_root?
    @parent.children.each {|child| return child unless (child == self) }
  end

  def to_s
    "#{name}"
  end

end
