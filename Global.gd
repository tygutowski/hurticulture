extends Node

enum ItemShape {Slot, TwoHigh, TwoL}

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
	HEAD_ACCENT = 7
}

enum PlayerHeads {
	CYBERPUNK = 0,
	SCIFI     = 1,
	STARWARS  = 2,
	STEAMPUNK = 3
}

var player_head_selected = PlayerHeads.CYBERPUNK
var player_eye_color: Color = Color(1.0, 1.0, 1.0)

var player_colors: Dictionary[int, Color] = {
	PlayerBodyPart.HYDRAULICS: Color(1.0,1.0,1.0),
	PlayerBodyPart.CHEST: Color(1.0,1.0,1.0),
	PlayerBodyPart.PELVIS: Color(1.0,1.0,1.0),
	PlayerBodyPart.LEGS: Color(1.0,1.0,1.0),
	PlayerBodyPart.FEET: Color(1.0,1.0,1.0),
	PlayerBodyPart.ARMS: Color(1.0,1.0,1.0),
	PlayerBodyPart.HEAD: Color(1.0,1.0,1.0),
	PlayerBodyPart.HEAD_ACCENT: Color(1.0,1.0,1.0),
}



enum SeedType {TEST}
var seed_type = SeedType.TEST

var seed_types: Dictionary = {
	SeedType.TEST: "PlantTest"
}

const INVENTORY_SLOT_SIZE: int = 64
const OFFLINE_MODE: bool = false
