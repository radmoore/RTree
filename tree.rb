#!/usr/bin/ruby

# VERSION Wed Mar 10 11:04:54 CET 2010

# TODO:
# * Add support for polytomy
# * Add other traversal strategies (inorder, postorder, level)
class Tree

  def initialize(lineage, polytomy=false)
    @nodes = Array.new
    @polytomy = polytomy
    @sep = "\t" # separator in to_lineage // to_s
    @traversal_strategy = 'pre'
    parse(lineage)
  end

  attr_reader :polytomy
  attr_accessor :sep

  # return string representation
  def to_s
    @nodes.each do |n|
      puts "node name: #{n}"
      if (n.is_root?)
        puts "\tParent node: root"
        puts "\tChild node: #{n.children}"
      elsif (n.is_leaf?)
        puts "\tParent node: #{n.parent}"
        puts "\tChild node: leaf node"
      else
        puts "\tParent node: #{n.parent}"
        puts "\tChild node: #{n.children}"
     
      end
    end
  end

  def add_node(name)
    node = Node.new(name)
    @nodes.push(node)
    return node
  end

  # return true if tree still has nodes (traversal)
  def has_nodes

  end

  # traverse the tree
  def traverse
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
        n = n.split(': ')[1] if (n.include?(':'))
        node = self.add_node(n)
        unless (pnode.nil?)
          node.add_parent_node(pnode)
          pnode.add_child_node(node)
        end
        pnode = node
      end
    end
     f.close
  end

end

class Node

  def initialize(name)
    @name = name
    @parent = nil
    @children = Array.new
    @associations = nil
  end

  attr_reader :name, :parent, :associations

  # add a child node
  def add_child_node(child_node)
    @children << child_node
  end

  # add a parent node
  def add_parent_node(parent_node)
    @parent = parent_node
  end

  # return true if node is leaf
  def is_leaf?
    @children.nil? ? true : false
  end

  def is_root?
    @parent.nil? ? true : false
  end

  # associate object with node
  def assoc_with_node
  end

  def to_s
    "#{name}"
  end

end


t = Tree.new(ARGV[0])
t.to_s
