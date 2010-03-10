#!/usr/bin/ruby -w

# VERSION Wed Mar 10 11:04:54 CET 2010

class Tree

  def init(lineage)
    parse(lineage)

  end

  # return string representation
  def toString
  end


  private

  # parse lineage file
  def parse(lineage)
  end

end


class Node

  def init
    @name
    @parent
    @children
    @associations
  end

  attr_reader :name, :parent, :children, :associations

  # add a child node
  def addChildNode
  end

  # add a parent node
  def addParentNode
  end

  # associate object with node
  def assocToNode
  end

end


t = Tree.new(ARGV[0])


