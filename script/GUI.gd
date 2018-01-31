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

# Selected gem in inventory
var select = null

func _inventory_changed():
	var inventory = player.inventory
	$Inventory/List.clear()
	
	for item in inventory:
		var count = inventory[item]
		$Inventory/List.add_item(item + ": " + str(count))
	
	# Reset sales
	if $Sales.visible:
		_open_sales()

func _open_sales():
	var inventory = player.inventory
	select = null

	$Sales/Inventory.clear()
	$Sales/Information.hide()

	for item in inventory:
		var count = inventory[item]
		$Sales/Inventory.add_item(item)
	
	$Sales/QuickSell.set_disabled(inventory.size() == 0)

	$Sales.show()

func _sales_info(index):
	var itemName = $Sales/Inventory.get_item_text(index)
	
	if not player.inventory.has(itemName):
		return _open_sales()
	
	var count = player.inventory[itemName]
	var price = price_tree[itemName]
	var priceAll = price * count
	
	select = itemName
	
	$Sales/Information/Count.set_text("Count: " + str(count))
	$Sales/Information/PricePer.set_text("Price per unit: " + str(price))
	$Sales/Information/PriceAll.set_text("Combined price: " + str(priceAll))
	
	$Sales/Information/Buttons/SellFive.set_disabled(count < 5)
	
	$Sales/Information/ItemName.set_text(itemName)
	$Sales/Information.show()

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
	if not select:
		return
	
	if not player.inventory.has(select):
		return
	
	var itemCount = player.inventory[select]

	if count == 0:
		sell_item(select, itemCount)
		return
	
	sell_item(select, count)

func _sell_all():
	var inv_clone = player.inventory.duplicate()
	for i in inv_clone:
		sell_item(i, inv_clone[i])

func _sales_reset():
	select = null
	$Sales/Information.hide()
	for i in range(0, $Sales/Inventory.get_item_count()):
		$Sales/Inventory.unselect(i)

func _ready():
	player.connect("inventory_changed", self, "_inventory_changed")
	
	$Inventory/Sales.connect("button_down", self, "_open_sales")
	$Sales/Inventory.connect("item_selected", self, "_sales_info")
	$Sales/Inventory.connect("nothing_selected", self, "_sales_reset")
	
	$Sales/Information/Buttons/SellAll.connect("button_down", self,"_sell_select", [0])
	$Sales/Information/Buttons/SellOne.connect("button_down", self,"_sell_select", [1])
	$Sales/Information/Buttons/SellFive.connect("button_down", self,"_sell_select", [5])
	
	$Sales/QuickSell.connect("button_down", self, "_sell_all")
	
	$Sales/Information.hide()
	pass

func _process(delta):
	$Money.set_text("Money: $" + str(player.money))
	
	if player.translation.x < 4:
		$Inventory.modulate.a = 0.5
	else:
		$Inventory.modulate.a = 1
