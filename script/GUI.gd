"""
Manages everything to do with the GUI
"""
extends Control

onready var player = get_node("/root/Root/Player")

# Prices for gem rocks
var price_tree = {
	"Sand": 1,
	"Topsoil": 5,
	"Dirt": 8,
	"Rock": 10,
	"Copper": 15,
	"Iron": 20,
	"Silver": 50,
	"Gold": 100,
	"Amethyst": 250,
	"Emerald": 300,
	"Sapphire": 400,
	"Ruby": 500,
	"Diamond": 1000,
	"Flawless Diamond": 2500
}

# Index: 1 - Pickaxes: Level; Name; Number; Delay; Strength; Health; Cost
# Index: 2 - Props: Scene; Name; Count; Cost
var shop_items = [
	[2, "props/Torch.tscn", "Torch", 5, 50],
	[2, "props/Bomb.tscn", "Bomb", 3, 150],
	[1, 1, "Rock", 10, 1, 250, null],
	[1, 2, "Copper", 9, 1.5, 300, 500],
	[1, 3, "Iron", 8, 2, 400, 1500],
	[1, 4, "Ruby", 7, 3, 500, 2000],
	[1, 5, "Diamond", 6, 5, 600, 5000],
	[1, 6, "Master", 5, 10, 700, 10000]
]

var props = []

# selected gem in inventory
var _sales_select = null
var _shop_select = null

var _prog_bar_h = 56

func _inventory_changed():
	var inventory = player.inventory
	$Inventory/List.clear()
	
	for item in inventory:
		var count = inventory[item]
		$Inventory/List.add_item(item + ": " + str(count))
	
	# Reset sales
	if $Sales.visible:
		_open_sales()

func _shop_info(index):
	var item = shop_items[index]
	
	if item[0] == 1:
		$Sales/Tabs/Buy/Information/ItemName.set_text(item[2] + " Pickaxe")
		$Sales/Tabs/Buy/Information/Count.hide()
		if item[1] < player.pickaxe_level or item[1] == player.pickaxe_level:
			$Sales/Tabs/Buy/Information/Price.set_text("Already owned!")
			$Sales/Tabs/Buy/Information/Buttons/Buy.set_disabled(true)
		else:
			$Sales/Tabs/Buy/Information/Price.set_text("Price: $" + str(item[6]))
			
			if player.money < item[6]:
				$Sales/Tabs/Buy/Information/Buttons/Buy.set_disabled(true)
			else:
				$Sales/Tabs/Buy/Information/Buttons/Buy.set_disabled(false)
	elif item[0] == 2:
		$Sales/Tabs/Buy/Information/ItemName.set_text(item[2])
		$Sales/Tabs/Buy/Information/Count.show()
		$Sales/Tabs/Buy/Information/Price.set_text("Price: $" + str(item[4]))
		$Sales/Tabs/Buy/Information/Count.set_text("Count: " + str(item[3]))
		
		if player.money < item[4]:
			$Sales/Tabs/Buy/Information/Buttons/Buy.set_disabled(true)
		else:
			$Sales/Tabs/Buy/Information/Buttons/Buy.set_disabled(false)
	
	_shop_select = index
	
	$Sales/Tabs/Buy/Information.show()

func _open_sales():
	var inventory = player.inventory
	_sales_select = null

	$Sales/Tabs/Sell/Inventory.clear()
	$Sales/Tabs/Sell/Information.hide()

	for item in inventory:
		var count = inventory[item]
		$Sales/Tabs/Sell/Inventory.add_item(item)
	
	$Sales/Tabs/Sell/QuickSell.set_disabled(inventory.size() == 0)
	
	# Buy

	$Sales/Tabs/Buy/ItemList.clear()
	$Sales/Tabs/Buy/Information.hide()
	
	for i in range(0, shop_items.size()):
		var item = shop_items[i]
		
		if item[0] == 1:
			if item[1] > player.pickaxe_level + 1:
				continue
		
			$Sales/Tabs/Buy/ItemList.add_item(item[2] + " Pickaxe")
		elif item[0] == 2:
			$Sales/Tabs/Buy/ItemList.add_item(item[2])
	
	$Sales.show()

func _sales_info(index):
	var itemName = $Sales/Tabs/Sell/Inventory.get_item_text(index)
	
	if not player.inventory.has(itemName):
		return _open_sales()
	
	var count = player.inventory[itemName]
	var price = price_tree[itemName]
	var priceAll = price * count
	
	_sales_select = itemName
	
	$Sales/Tabs/Sell/Information/Count.set_text("Count: " + str(count))
	$Sales/Tabs/Sell/Information/PricePer.set_text("Price per unit: $" + str(price))
	$Sales/Tabs/Sell/Information/PriceAll.set_text("Combined price: $" + str(priceAll))
	
	$Sales/Tabs/Sell/Information/Buttons/SellFive.set_disabled(count < 5)
	
	$Sales/Tabs/Sell/Information/ItemName.set_text(itemName)
	$Sales/Tabs/Sell/Information.show()

func sell_item(item, count):
	if not player.inventory.has(item):
		return

	if player.inventory[item] < count:
		return
	
	var price = price_tree[item]
	var price_total = price * count
	
	player.inventory[item] = player.inventory[item] - count
	player.money = player.money + price_total
	
	if player.inventory[item] == 0:
		player.inventory.erase(item)

	player.emit_signal("inventory_changed")

func _sell_select(count):
	if _sales_select == null:
		return
	
	if not player.inventory.has(_sales_select):
		return
	
	var itemCount = player.inventory[_sales_select]

	if count == 0:
		sell_item(_sales_select, itemCount)
		return
	
	sell_item(_sales_select, count)

func _sell_all():
	var inv_clone = player.inventory.duplicate()
	for i in inv_clone:
		sell_item(i, inv_clone[i])

func _sales_reset():
	_sales_select = null
	$Sales/Tabs/Sell/Information.hide()
	for i in range(0, $Sales/Tabs/Sell/Inventory.get_item_count()):
		$Sales/Tabs/Sell/Inventory.unselect(i)

func _shop_reset():
	_shop_select = null
	$Sales/Tabs/Buy/Information.hide()
	for i in range(0, $Sales/Tabs/Buy/ItemList.get_item_count()):
		$Sales/Tabs/Buy/ItemList.unselect(i)

func _buy_select():
	if _shop_select == null:
		return
	
	var item = shop_items[_shop_select]
	
	if item[0] == 1:
		if player.money < item[6]:
			return
		
		player.money -= item[6]
		player.pickaxe_level = item[1]
		_open_sales()
		player.pickaxe_delay = item[3]
		player.pickaxe_strength = item[4]
		player.pickaxe_health_max = item[5]
		
		$Pickaxe/PickName.set_text(item[2] + " Pickaxe")
	elif item[0] == 2:
		if player.money < item[4]:
			return
		
		player.money -= item[4]
		
		player.props[item[2]] += item[3]
	
	$BuySound.play()

func _repair_dialog():
	if player.pickaxe_health > player.pickaxe_health_max - 5:
		return

	var repair_cost = player.pickaxe_health_max - player.pickaxe_health
	$Repair.set_text("Repair pickaxe for $" + str(repair_cost) + "?")
	$Repair.show()

func _repair():
	var repair_cost = player.pickaxe_health_max - player.pickaxe_health + 5
	
	if player.money < repair_cost:
		return
	
	player.money -= repair_cost
	player.pickaxe_health = player.pickaxe_health_max

func _place_prop(inx, name):
	print(name)
	var prop_count = player.props[name]
	
	if prop_count == 0:
		return
	
	var prop = props[inx].duplicate()

	prop.set_translation(Vector3(floor(player.translation.x) + 0.5, floor(player.translation.y) + 0.5, prop.translation.z))
	get_node("../").add_child(prop)
	
	player.props[name] -= 1

func _ready():
	player.connect("inventory_changed", self, "_inventory_changed")
	
	$Inventory/Sales.connect("button_down", self, "_open_sales")
	$Sales/Tabs/Sell/Inventory.connect("item_selected", self, "_sales_info")
	$Sales/Tabs/Sell/Inventory.connect("nothing_selected", self, "_sales_reset")
	
	$Sales/Tabs/Sell/Information/Buttons/SellAll.connect("button_down", self,"_sell_select", [0])
	$Sales/Tabs/Sell/Information/Buttons/SellOne.connect("button_down", self,"_sell__select", [1])
	$Sales/Tabs/Sell/Information/Buttons/SellFive.connect("button_down", self,"_sell_select", [5])
	
	$Sales/Tabs/Sell/QuickSell.connect("button_down", self, "_sell_all")
	
	$Sales/Tabs/Sell/Information.hide()
	
	$Sales/Tabs/Buy/ItemList.connect("item_selected", self, "_shop_info")
	$Sales/Tabs/Buy/ItemList.connect("nothing_selected", self, "_shop_reset")
	$Sales/Tabs/Buy/Information/Buttons/Buy.connect("button_down", self, "_buy_select")
	
	$Pickaxe/QuickRepair.connect("button_down", self, "_repair_dialog")
	$Repair.connect("confirmed", self, "_repair")
	
	$Powerups/Torch.connect("button_down", self, "_place_prop", [0, "Torch"])
	$Powerups/Bomb.connect("button_down", self, "_place_prop", [1, "Bomb"])
	
	for i in shop_items:
		if i[0] == 2:
			props.append(load("res://scene/" + i[1]).instance())

func _process(delta):
	$Money.set_text("Money: $" + str(player.money))
	
	var percent = float(player.pickaxe_health) / float(player.pickaxe_health_max)
	var bar_size = floor(float(_prog_bar_h) * percent)
	
	$Pickaxe/PickIcon/DurabilityBar.set_size(Vector2(bar_size, 13))
	
	$Powerups/Torch/Count.set_text(str(player.props["Torch"]))
	$Powerups/Bomb/Count.set_text(str(player.props["Bomb"]))
	
	if player.translation.x < 4:
		$Inventory.modulate.a = 0.5
	else:
		$Inventory.modulate.a = 1
