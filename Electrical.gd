class_name Electrical
extends Node3D

enum ElectricalState { OFF, ON, STANDBY, EMERGENCY }
@export var state: ElectricalState = ElectricalState.OFF
@export var power_consumption: float = 0.0
@export var interruptable : bool

func interact() -> void:
	pass

func power_outage() -> void:
	pass

func power_return() -> void:
	pass
