#!/usr/bin/ruby -w

require 'tree'

tree = Tree.new(ARGV[0])
puts tree.to_s(true)
