#!/usr/bin/env python 

import os
import sys 
import re
from string import strip
from ete2 import TreeNode, Tree

# This sets Unbuffered stdout/auto-flush
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

id2node= {}
node2parentid = {}
all_ids = set([])
all_nodes = []
id2name= {}
id2type= {}
id2rank= {}

# Loads info from NCBI taxonomy files
if os.path.exists("/global/projectb/sandbox/rqc/qcdb/taxonomy/tax/2013.08.09/nodes.dmp"):
    NODESFILE = open('/global/projectb/sandbox/rqc/qcdb/taxonomy/tax/2013.08.09/nodes.dmp')
else:
    print '"nodes.dmp" file is missing. Try to downloaded from: '

if os.path.exists("/global/projectb/sandbox/rqc/qcdb/taxonomy/tax/2013.08.09/names.dmp"):
    NAMESFILE = open('/global/projectb/sandbox/rqc/qcdb/taxonomy/tax/2013.08.09/names.dmp')
else:
    print '"names.dmp" file is missing. Try to downloaded from: '

# Reads taxid/names transaltion
#print 'Loading species names from "names.dmp" file...',
for line in NAMESFILE:
    line = line.strip()
    fields = map(strip, line.split("|"))
    nodeid, name, ndel, ntype = fields[0], fields[1], fields[2], fields[3]
    if ntype=="scientific name":
    	id2name[nodeid] = name
    	id2type[nodeid] = ntype

#print len(id2name)

# Reads node connections in nodes.dmp
#print 'Loading node connections form "nodes.dmp" file...', 
for line in NODESFILE:
    line = line.strip()
    fields = map(strip, line.split("|"))
    nodeid, parentid, nrank = fields[0], fields[1], fields[2]
    
    if nodeid =="" or parentid == "":
	raw_input("Wrong nodeid!")

    # Stores node connections
    all_ids.update([nodeid, parentid])

    # Creates a new TreeNode instance for each new node in file
    n = TreeNode()
    # Sets some TreeNode attributes
    n.add_feature("name", id2name[nodeid])
    n.add_feature("taxid", nodeid)
    n.add_feature("nrank", nrank)
    n.add_feature("ntype", id2type[nodeid])

    # updates node list and connections
    node2parentid[n]=parentid
    id2node[nodeid] = n
    id2rank[nodeid] = nrank
#print len(id2node)

# Reconstruct tree topology from previously stored tree connections
#print 'Reconstructing tree topology...'
for node in id2node.itervalues():
    parentid = node2parentid[node]
    parent = id2node[parentid]
    # node with taxid=1 is the root of the tree
    if node.taxid == "1":
	t = node
    else:
        parent.add_child(node)

# Let's play with the tree
def get_track(node):
    ''' Returns the taxonomy track from leaf to root'''
    track = []
    while node is not None:
	if(re.search(node.nrank,"genusspeciesfamilyphylumclassordersuperkingdom") or re.search(node.name,"cellular organisms")):
        	track.append(node.name) # You can add name or taxid
        node = node.up
    #print
    return track

#print "The tree contains %d leaf species" %len(t)
taxid = None
for taxid in id2name:
    if id2rank[taxid]=="species":
	target_node =  id2node[taxid]
	print "root\t"+'\t'.join(get_track(target_node)[::-1])

sys.exit()
