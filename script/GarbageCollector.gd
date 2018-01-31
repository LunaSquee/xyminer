extends Node

var _node_cache = []

var _clock = 0

func _process_trash():
	var passable = []
	var cleanup_time = OS.get_unix_time()
	for i in range(0, _node_cache.size()):
		var trash = _node_cache[i]

		if trash["dies"] < cleanup_time:
			
			if not trash["node"]:
				continue
			
			trash["node"].queue_free()
			continue

		passable.append(trash)
	
	_node_cache = passable

func _ready():
	pass

# Add a node to be garbage collected
func add_trash(node, lifetime = 0):
	var added = OS.get_unix_time()
	var die = added + lifetime
	
	_node_cache.append({"node": node, "added": added, "dies": die})

func _process(delta):
	_clock += 1
	_clock %= 100
	
	if _clock == 0:
		_process_trash()