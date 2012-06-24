RTree
==================
Rtree is a simple Ruby class for creating and traversing a tree. It
creates a tree from a file containing a [newick tree](http://en.wikipedia.org/wiki/Newick_format "Newick format description").
Supports different traversal methods, and supplies an iterator to move through the tree 
based on the current traversal order. Any object can be associated with any node in the tree, 
and accessed by a predefined key.

###### Website:
http://iebservices.uni-muenster.de/radmoore/rtree

###### Installation:
RTree is available as a gem. To install, add the source and run gem install
<pre>
 $ gem sources --add http://iebservices.uni-muenster.de/radmoore/gems/
 $ sudo gem install rtree
</pre>

###### Example:
```ruby
 require 'rtree'

 tree = RTree.new(taxa.newick)   # create new tree from file
 tree.set_traversal_mode('post') # traverse tree in postorder 
 while(tree.has_node?)           # use iterator to iterate over tree
   n = tree.next_node            # get next node
   if (n.name == 'Homo sapiens') 
     n.add_data('proteins', [proteinsA, proteinB]) # associate data with node
     s = n.get_sibling           # get sibling node
     s.add_data('orthologs', [proteinC, proteinD]) # associate data with node
   end
 end
 
 n = tree.get_node('dmel') # get a particular node
 puts n.lineage            
 => Bilateria;Endopterygota;Diptera;Drosophila;dmel
```

###### License	
Distributes under the same terms as Ruby

###### Tested on	
ruby 1.8.7 (2010-06-23 patchlevel 299) [i686-linux]

###### Requires	
digest/md5