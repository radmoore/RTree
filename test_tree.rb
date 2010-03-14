#!/usr/bin/ruby -w

require 'tree'

# create tree
tree = Tree.new(ARGV.shift)

# read all xdoms, and associate doms with tree nodes
ARGV.each do |xdom|
	name = xdom.split('.')[0]
	node = tree.get_node(name)
	doms = Hash.new
	IO.foreach(xdom) {|line|
		next if (/^>.+/.match(line))
		(s, e, d, ev) = line.split
		doms[d] = 1
	}
	node.add_data("domains", doms)
end

# get all node names, and save in hash
nodes = Hash.new
tree.get_node_names.each {|n| nodes[n] = 0}

# first run, from leaf to root:
# assign 1 if both child nodes have domain x
# or 0 if only one
def leaf2root(node)
	return if node.is_root?
	doms = Hash.new
	cdoms = node.get_data('domains')
	#print "node: #{node}: "
	#puts cdoms.inspect
	sister = node.get_sibling
	sdoms = sister.get_data('domains')
	#print "node: #{sister}: "
	#puts sdoms.inspect
	(cdoms.keys | sdoms.keys).each do |d|
		if (cdoms.has_key?(d) && sdoms.has_key?(d))
			if (cdoms[d] == 1 || sdoms[d] == 1)
				(cdoms[d] == 1) ? sdoms[d] = 1 : cdoms[d] = 1 # ?
				doms[d] = 1
			end
		else	
			doms[d] = 0
		end
	end

	parent = sister.parent
	parent.add_data('domains', doms)
	leaf2root(parent)
end

# second run, from root to leafs
def root2leafs(node)
	return if node.is_leaf?
	pdata = node.get_data('domains')
	node.children.each do |child|
		outstring = Array.new
		gain = 0
		loss = 0
		cdata = child.get_data('domains')
		outstring.push(node.name)
		outstring.push(child.name)
		(pdata.keys | cdata.keys).each do |d|
			if (pdata.has_key?(d) && cdata.has_key?(d))

				# 1. case: no state change
				next if (pdata[d] == cdata[d])
				# 2. case:
				gain += 1 if (pdata[d] == 0 && cdata[d] == 1) # child has domain, but parent doesnt
				loss += 1 if (pdata[d] == 1 && cdata[d] == 0) # parent has domain, but child doesnt

			# child can have nodes not present in parent
			else
				gain += 1
			end
		end
		outstring.push(gain)
		outstring.push(loss)
		puts outstring.join("\t")
		root2leafs(child)
	end
	
end


# first run, determine internal nodes
leaf2root(tree.get_node('S1'))

# reset all unknown at root to known
root = tree.root_node

while(tree.has_nodes?)
	n = tree.next_node
	puts "node: #{n}"
	puts n.get_data('domains').inspect
end
puts
puts "parent\tchild\tgains\tlosses"
root2leafs(tree.root_node)







