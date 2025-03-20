extends Node

enum ItemShape {Slot, TwoHigh, TwoL}

var item_shape_slot_occupation: Dictionary[int, Array] = {
	Global.ItemShape.Slot        : [Vector2i(0, 0)],
	Global.ItemShape.TwoHigh     : [Vector2i(0, 0), Vector2i(0, 1)],
	Global.ItemShape.TwoL        : [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
}

enum SeedType {TEST}
var seed_type = SeedType.TEST

var seed_types: Dictionary = {
	SeedType.TEST: "PlantTest"
}
