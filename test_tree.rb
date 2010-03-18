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


def leaf2root(cnode)

	return if cnode.is_root?

	doms 		= Hash.new
	cdoms 	= cnode.get_data('domains')
	snode 	= cnode.get_sibling
	sdoms 	= snode.get_data('domains')

	if (sdoms.nil?)
		leaf2root(snode.left_child)
		return
	end

	(cdoms.keys | sdoms.keys).each do |d|

		if (cdoms.has_key?(d) && sdoms.has_key?(d))

			if ((not cnode.is_leaf?) or (not snode.is_leaf?))
				if (cdoms[d].nil? or sdoms[d].nil?)
					doms[d] = 1
					next
				end
			end
			doms[d] = (cdoms[d] == sdoms[d]) ? cdoms[d] : nil
		else
			doms[d] = nil
		end
	end

	pnode = cnode.parent
	pnode.add_data('domains', doms)
	leaf2root(pnode)
end


def root2leafs(tree)
	tree.reset
	tree.set_traversal_strategy('pre')
	while(tree.has_nodes?)
		node = tree.next_node
		next if node.is_root?
		next if node.is_leaf?
		cdoms = node.get_data('domains')
		parent = node.parent
		pdoms = parent.get_data('domains')
		cdoms.keys.each { |d| 
			cdoms[d] = 1 	if (cdoms[d].nil? && pdoms[d] == 1) 
		}
		node.add_data('domains', cdoms)
	end
	
	tree.reset
	while(tree.has_nodes?)
		n = tree.next_node
		doms = n.get_data('domains')
		n.add_data('domains', doms.delete_if { |k, v| v.nil? })
	end

end


# second run, from root to leafs
def root2leafs_old(node)
	return if node.is_leaf?
	pdata = node.get_data('domains')
	node.children.each do |child|
		cdata = child.get_data('domains')
		(pdata.keys | cdata.keys).each do |d|
			if (pdata.has_key?(d) && cdata.has_key?(d))
				next if (pdata[d] == cdata[d])
				cdata[d] = pdata[d] if (cdata[d] == 0) #child node state is set to parent if child node state is unknown
				child.add_data('domains', cdata)
			end
		end
		root2leafs(child)
	end
end

def count_events(node)

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
				next if (pdata[d] == cdata[d])
				
			end
		end
		outstring.push(gain)
		outstring.push(loss)
		puts outstring.join("\t")
		#root2leafs(child)
	end



end
# first run, determine internal nodes
leaf2root(tree.get_node('S1'))
# second run, from root to leafs
root2leafs(tree)

#while(tree.has_nodes?)
#	n = tree.next_node
#	puts "node: #{n}"
#	puts n.get_data('domains').inspect
#end
tree.reset
while(tree.has_nodes?)
	n = tree.next_node
	puts "node: #{n}"
	puts n.get_data('domains').inspect
end


puts
puts "parent\tchild\tgains\tlosses"
#count_events(tree.root_node)






