extends Node

# This is a collection of general data that can be referenced from anywhere
# This is NOT meant to store unique player data, but rather constants.

enum ItemShape {Slot, TwoHigh, TwoL}

enum biomeEnum {
	CARBON_WASTES,
	SKYLOOM_MEADOW
}
var item_shape_slot_occupation: Dictionary[int, Array] = {
	Global.ItemShape.Slot        : [Vector2i(0, 0)],
	Global.ItemShape.TwoHigh     : [Vector2i(0, 0), Vector2i(0, 1)],
	Global.ItemShape.TwoL        : [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
}

enum PlayerBodyPart {
	HYDRAULICS  = 0,
	CHEST       = 1,
	PELVIS      = 2,
	LEGS        = 3,
	FEET        = 4,
	ARMS        = 5,
	HEAD        = 6,
	HEAD_ACCENT = 7,
	EYES        = 8
}

enum PlayerHeads {
	CYBERPUNK = 0,
	SCIFI     = 1,
	STARWARS  = 2,
	STEAMPUNK = 3
}

enum SeedType {TEST}
var seed_type = SeedType.TEST

var seed_types: Dictionary = {
	SeedType.TEST: "PlantTest"
}

const INVENTORY_SLOT_SIZE: int = 64
const OFFLINE_MODE: bool = false
