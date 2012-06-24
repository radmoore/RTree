#!/usr/bin/ruby -w

require 'digest/md5'

# Exception thrown if newick tree cannot be parsed
class TreeParseError < RuntimeError #:nodoc:
end

# Exception thrown when attempting to access a node
# using a node name not present in the Tree
class UnkownNodeError < RuntimeError #:nodoc:
end

# Exception thrown if tree traversal is set
# to something other than 'pre' or 'post'
class UnkownTraveralModeError < RuntimeError #:nodoc:
end

# == Tree - A class for creating and traversing a tree
# Creates a tree from a file containing a newick tree.
# Supports different breadth-first traversal methods,
# and supplies an iterator to move through the tree based
# on the current traversal order. Any object can be associated
# with any node in the tree, and accessed by a predefined key.
# 
# === Example:
#
# require 'rtree'
#
#  tree = RTree.new(taxa.newick)   # create new tree from file
#  tree.set_traversal_mode('post') # traverse tree in postorder 
#  while(tree.has_next?)           # use iterator to iterate over tree
#    n = tree.next_node            # get next node
#    if (n.name == 'Homo sapiens') 
#      n.add_data('genes', [CCDS9344, CCDS9356]) # associate data with node
#    end
#  end
# 
# === Misc
# Author:: Andrew D. Moore (radmoore@uni-muenster.de)
# Copyright:: Copyright (c) 2010 - 2011
#             Evolutionary Bioinformatics Group
#             Institute for Evolution and Biodiversity
#             University of Muenster, Germany
# License::   Distributed under the same terms of Ruby
# Requires:: digest/md5
# Tested on:: Ruby 1.8.7 (2010-06-23 patchlevel 299) [i686-linux]
# Open Issues::
# * Support for polytomy
# * Inorder traversal
class RTree

  # Create a new tree using a newick formated string
  # in +file+
  #
  # * file:: a file containing a newick formatted string
  def initialize(file)
    @nodes = Hash.new
    @traversal_mode = 'pre'
    @visited = Hash.new
    newickstr = read_tree_file(file)
    tokenizer = NewickTokenizer.new(newickstr)
    @root_node = build(tokenizer, nil)
    @cnode = @root_node
  end

  attr_reader :root_node, :traversal_mode
  attr_accessor :sep

  # Returns a string version of +self+ in newick
  # format. If +inode+ is +true+, internal nodes
  # will be named.
  #
  # * inodes:: A boolean indicating whether or not to show internal node names
  def to_s(inodes=true)
    return newick_string(@root_node, inodes)+";"
  end

  # return subtree with current node
  # as root, a passed node as root
	# or nil if node is child
  # TODO
  def prune(node_name=@cnode.name) #:nodoc:
  end

  # prune in place
  # TODO
  def prune!(node_name) #:nodoc:
  end

  # Returns +true+ if there still are nodes
  # in the current iteration, other +false+
  def has_nodes?
   @visited.keys.size < @nodes.keys.size ? true : false
  end

  # Returns +true+ if node with +name+ is present in _self,
  # +false+ otherwise
  #
  # * node_name:: The name of a node
  def node_exists?(node_name)
    @nodes.has_key?(node_name)
  end

  # Adds a node to +self+. Returns 
  # the added node
  #
  # * name:: name of new node to add
  # TODO: this node is empty
  def add_node(name)
    node = Node.new(name)
    @nodes[name] = node
  end

  # Sets the mode of traversal, raises
  # +UnkownTraversalMode+ if mode is unknown.
  # Currently only supports 'pre' and 'post'
  # See http://en.wikipedia.org/wiki/Tree_traversal
  #
  # * s:: String representing the travesal mode to use (pre / post)
  def set_traversal_mode(s="pre")
    raise UnkownTraveralModeError, "Unknown travseral strategy" unless (s == "pre" || s == 'post')
    @traversal_mode = s
    return
  end
 
  # Returns an Array with all node names
  # present in +self+. This array is not ordered.
  # For a list of nodes ordered by the current traversal
  # mode, see Tree.traverse
	def get_node_names
		@nodes.keys
	end

  # Returns the node from +self+ identified by
  # +node_name+. Raises +UnkownNode+ if a node with
  # +node_name+ does not exist in +self+
  # * node_name:: name of node to retreive
  def get_node(node_name)
    raise UnkownNodeError, "Node #{node_name} is not defined" unless (self.node_exists?(node_name))
    @nodes[node_name]
  end

  # Returns an array with child nodes of the node identified by +node_name+.
  # Raises +UnknownNode+ exception if a +node_name+ does not
  # exist in +self+. Returns +nil+ if +node_name+ identifies a leaf node
  def get_child_nodes(node_name)
    raise UnkownNodeError, "Node #{node_name} is not defined" unless (self.node_exists?(node_name))
    return ( @node[node_name].is_leaf? ) ? nil : @nodes[node_name].children
  end

  # Returns the parent node of the node identified by +node_name+.
  # Raises +UnknownNode+ exception if a +node_name+ does not
  # exist in +self+. Returns +nil+ if +node_name+ identifies the root node
  def get_parent_node(node_name)
    raise UnkownNodeError, "Node #{node_name} is not defined" unless (self.node_exists?(node_name))
    return ( @node[node_name].is_root? ) ? nil : @nodes[node_name].parent
  end

  # Resets the iterator of +self+; the current
  # node of the tree is set to the root of +self+
  def reset
		@visited = Hash.new
    @cnode = @root_node
		return
  end

	# Wrapper for Tree.next_node.
	# Returns Array of nodes ordered by the current traversal mode
  # (see Tree.set_traversal_mode)
	def traverse
		a = Array.new
		while(self.has_nodes?) do a << self.next_node end
		return a
	end	

  # --
	# TODO:
	# + sanitize
	# + efficiency (vars if start_node is used)
  # return next node given the
  # traversal strategy
	# if a start node is passed, the next node
	# in the sequence based on the traversal strategy
	# will be returned. However, this can not be used for iteration
	# as nodes are never set to visited.
  # ++

  # If +start_node+ == +nil+, returns the next node given the current
  # iteration strategy. If +start_node+ != nil,
  # returns the next node without advancing the iterator.
  # Ergo, do not use +start_node+ if iteration is to be used.
  def next_node(start_node=nil)
    node = @cnode
    if (self.traversal_mode == 'pre')
			if (start_node.nil?)
	    	@visited[node.name] = 0
				pre_traversal(node)
			else
				node_bck = @cnode
				pre_traversal(start_node)
				node = @cnode
				@cnode = node_bck
			end
		elsif (self.traversal_mode == 'post')
			post_traversal(node)
			node = @cnode
			
    	@visited[node.name] = 0
		end
    return node
  end
	
  private

  # DEFAULT
	# Visit root, then left subtree, then right subtree
  def pre_traversal(node) # :nodoc:
		return if @visited.keys.length == @nodes.keys.length
    if node.is_leaf?
			unless (visited?(node))
				@cnode = node
				return
			end
    else
			unless (visited?(node.left_child))
				@cnode = node.left_child
				return
			end			
			unless (visited?(node.right_child))
				@cnode = node.right_child
				return
			end			
    end
		pre_traversal(node.parent)
  end

	# Visit left subtree, then right subtree, then root
	def post_traversal(node) # :nodoc:
		return if @visited.keys.length == @nodes.keys.length
		if node.is_leaf?
			unless (visited?(node))
				@cnode = node
				return
			end
		else
			unless (visited?(node.left_child))
				post_traversal(node.left_child)
				return
			end
			unless (visited?(node.right_child))
				post_traversal(node.right_child)
				return
			end
			unless (visited?(node))
				@cnode = node
				return
			end
		end
		post_traversal(node.parent)
	end

  # For iteration, returns true if _node_ has
  # already be visited in current iteration
  def visited?(node) # :nodoc:
    @visited.has_key?(node.name)
  end

  # Reads a file containing a newick tree. Returns
  # a string in newick format
  def read_tree_file(file) # :nodoc:
    treestr = String.new
    IO.foreach(file) {|line| treestr += line.chomp}
    return treestr
  end

  # TODO: 
  # - checks to the presence of node.name
  #   in nodes hash should not be necessary
  # - add support for edge weight
  def build(tokenizer, parent) # :nodoc:
    
    while(tokenizer.has_next?)

      token = tokenizer.next_token
      
      if (token.type == "LAB")
        node = Node.new(token.value)
        @nodes[token.value] = node unless @nodes.has_key?(token.value)
        return node

      elsif (token.value == '(')
        rand_name = Digest::MD5.hexdigest(Time.new.hash.to_s)
        pnode = Node.new("inode_#{rand_name}")
        loop do 
          child = build(tokenizer, node)
          @nodes[child.name] = child unless @nodes.has_key?(child.name)
          pnode.add_child_node(child)
          break if (tokenizer.check_next.value != ',')
          tokenizer.next_token
        end

        if (tokenizer.next_token.value != ")")
          raise TreeError, "Expected ')' but found: #{token.value}"

        else
          peek = tokenizer.check_next
          if ( peek.value == ")" || peek.value == "," || peek.value == ";" )
            @nodes[pnode.name] = pnode unless @nodes.has_key?(pnode.name)
            return node
          elsif (peek.type == "LAB")
            token = tokenizer.next_token
            pnode.name = token.value
            @nodes[pnode.name] = node unless @nodes.has_key?(pnode.name)
            return pnode
          end
        end
      end

    end

  end

  # Called by to_s
  def newick_string(node, inodes) # :nodoc:
    out = String.new
    if (not node.is_leaf?) 
      out += "("
      node.children.each {|child|
        out += newick_string(child, inodes)
        out += "," if child != node.children.last
      }
      out += inodes ? ")#{node.to_s}" : ")"
    elsif (node.is_leaf?)
      out += node.to_s
    end
    return out
  end

  # parse lineage file
  # DEPRECATED
  def parse_lineage(lineage) # :nodoc:
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

# END RTree
end

# Node - A Node of a Tree
#
# Class to represent a node of a tree
#
# Author:: Andrew D. Moore [radmoore@uni-muenster.de]
class Node

  # Create a new node with name +name+
  def initialize(name)
    @name = name
    @parent = nil
    @children = Array.new
    @associations = Hash.new
  end

  attr_accessor :name, :parent
  attr_reader :children, :associations

  # Adds +child_node+ as child to +self+, and 
  # +self+ as parent node to _child_node_
  def add_child_node(child_node)
    unless (@children.include?(child_node))
      child_node.parent = self
      @children << child_node 
    end
  end

  # Returns +true+ if +self+ has
  # child, +false+ otherwise
  def has_children?
    not @children.nil?
  end

  # Returns +true+ if +self+ is
  # leaf, otherwise +false+
  def is_leaf?
    @children.empty? ? true : false
  end

  # Returns +true+ if+self+ is a root node,
  # +false+ otherwise
  def is_root?
    @parent.nil? ? true : false
  end

  # Returns the left child of +self+,
  # or +nil+ if +self+ is a leaf
  def left_child
    return nil if self.is_leaf?
    self.children[0]
  end

  # Returns the right child of +self+,
  # or +nil+ if +self+ is a leaf
  def right_child
    return nil if self.is_leaf?
    self.children[1]
  end

  # Associates any type of data / object
  # with +self+, where +name+ must
  # be unique. Re-using +name+ will overwrite
  # any previously defined data associated with
  # +self+. Returns +data+
  def add_data(name, data)
		@associations[name] = data
  end

  # Returns the data associated with +self+ by +name+,
  # or +nil+ if no such data exists
	def get_data(name)
		return nil unless (@associations.has_key?(name))
		@associations[name]
	end	

  # Returns sister taxa, root of neighbouring subtree
  # or nil if +self+ is root node
  def get_sibling
    return nil if self.is_root?
    @parent.children.each {|child| return child unless (child == self) }
  end

  # Returns the name of +self+, with all spaces replaced
  # (required for newick)
  def to_s
    self.name.gsub(/\s/, '_')
  end

  # Returns the lineage of +self+ starting
  # at the root of the tree in which +self+ is a node.
  # Nodes in the lineage are separated by +sep+
  def to_lineage(sep=';')
    out = Array.new
    node = self
    return node.name if node.is_root?
    loop do
      out << node.name
      node = node.parent
      if (node.is_root?)
        out << node.name
        return out.reverse.join(sep)
      end
    end
  end

# END NODE
end

# NewickTokenizer - Parse a newick formatted string into its tokens. 
# 
# This code is inspired by the newick-ruby gem written by Jonathan Badger 
# (https://github.com/jhbadger/Newick-ruby),
# and is based on the newick format described here
# http://evolution.genetics.washington.edu/phylip/newick_doc.html
# 
# Author:: Andrew D. Moore [radmoore@uni-muenster.de]
# Open Issues::
# * No support for edge weights/bootstrap
class NewickTokenizer

  # A token has a type and a value
  Token = Struct.new(:type, :value)

  # Create a new NewickTokenizer
  # +string+ string in newick format
  def initialize(string)
    @str = string  
    @pos = 0
  end

  # Reset the current position to 0
  # (for iteration)
  def rewind
    @pos = 0
    return
  end

  # Returns the next next charater in the string,
  # or nil if no characters are left
  def next_char
    c = (@pos < @str.length) ? @str[@pos].chr : nil
    @pos += 1
    return c
  end

  # Returns true if +self+ still has a token,
  # false otherwise
  # ++
  # TODO: double check, this will also return true if
  # the string still has chars, not necessarily tokens
  # --
  def has_next?
    @pos < @str.length
  end

  # Returns the next token of +self+
  # Currently only two types are recognized:
  # * symbol
  # * label
  def next_token
    c = next_char
    if (c == " ")
      return next_token
    elsif (c == "(" || c == ")" || c == ',')
      return Token.new("SYM", c)
    elsif (@str.index(/([^,():;]+)/, @pos-1) == @pos-1)
      @pos += $1.length-1
      return Token.new("LAB", $1)
    end
  end

  # Returns the next token without moving 
  # the position of +self+ (that is,
  # a call to self.next_token will return the same
  # token)
  def check_next
    token = next_token
    @pos -= token.value.length
    return token
  end

# END NewickTokenizer
end
