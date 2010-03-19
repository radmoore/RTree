#!/usr/bin/ruby -w

require 'tree'



def create_tree(lineage)
  tree = Tree.new(lineage)
end


def add_domains_to_nodes(xdom_list, tree)
  xdom_list.each do |xdom|
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
end

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
			next if (pdata.has_key?(d) && cdata.has_key?(d))
      loss += 1 if (pdata.has_key?(d))
      gain += 1 if (cdata.has_key?(d))
		end
		outstring.push(gain)
		outstring.push(loss)
		puts outstring.join("\t")

		count_events(child)

	end
end

def inspect_pseudos(tree)

  tree.reset
  while(tree.has_nodes?)
  	n = tree.next_node
  	puts "node: #{n}"
  	puts n.get_data('domains').inspect
  end

end


def main

  lineage_file = ARGV.shift
  xdom_list = ARGV
  tree = create_tree(lineage_file)
  add_domains_to_nodes(xdom_list, tree)
  # first run, determine internal nodes
  leaf2root(tree.get_node('S1'))
  # second run, from root to leafs
  root2leafs(tree)

  puts "NODE CONTENTS:"
  puts "="*20
  inspect_pseudos(tree)
  puts ""
  puts "EVENTS:"
  puts "="*20
  puts "parent\tchild\tgains\tlosses"
  count_events(tree.root_node)
 



end

abort "Usage: #{$0} LINEAGE_FILE 1.xdom, 2.xdom ..." unless (ARGV.size > 1)

### MAIN ###
main()

