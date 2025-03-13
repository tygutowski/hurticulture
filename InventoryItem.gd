class_name InventoryItem
extends TextureRect

enum ItemShape {Slot, TwoLine, ThreeLine, FourLine,
			TwoSquare, ThreeSquare, FourSquare,
			TwoL, OddL, ThreeL}

var item_shape_slot_occupation = {
	ItemShape.Slot        : [Vector2(0, 0)],
	ItemShape.TwoLine     : [Vector2(0, 0), Vector2(1, 0)],
	ItemShape.ThreeLine   : [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
	ItemShape.TwoSquare   : [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
	ItemShape.ThreeSquare : [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)],
	ItemShape.TwoL        : [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)],
	ItemShape.OddL        : [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(2, 0)],
	ItemShape.ThreeL      : [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(2, 0), Vector2(0, 2)],
}

@export var shape: ItemShape

var rot = 0
var slot = Vector2i(-1, -1)
var occupying_slots = []

func _ready() -> void:
	check_occupying_slots()

func _process(_delta: float) -> void:
	print(occupying_slots)

func check_occupying_slots() -> void:
	occupying_slots = []

func rotate_90_cw() -> void:
	var new_slots = []
	for slot in occupying_slots:
		var x = slot.x
		var y = slot.y
		new_slots.append(Vector2(y, -x))  # (x', y') = (y, -x)
	occupying_slots = new_slots
