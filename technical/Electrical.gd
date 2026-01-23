extends Node3D
class_name Electrical

@export var wire_scene: PackedScene
@export var electrical_type: Type
var wires_to: Dictionary[Electrical, Path3D] = {}
var disabled: bool = false
var last_position: Vector3
enum Type {
	PRODUCER,
	CONNECTOR,
	CONSUMER,
	SWITCH,
}

var has_power: bool = false
var nodes: Array[Electrical] = []
var id: int = -1

static var global_id: int = 0
static func assign_id() -> int:
	global_id += 1
	return global_id

func _ready() -> void:
	last_position = global_position
	id = Electrical.assign_id()

func _process(_delta: float) -> void:
	if global_position != last_position:
		last_position = global_position
		update_wires()

func update_wires() -> void:
	for other: Electrical in wires_to.keys():
		var wire: Path3D = wires_to[other]

		if not is_instance_valid(other) or not is_instance_valid(wire):
			continue

		var curve: Curve3D = wire.curve
		curve.set_point_position(0, wire.to_local(global_position))
		curve.set_point_out(0, Vector3(0, -0.5, 0))
		curve.set_point_position(1, wire.to_local(other.global_position))
		curve.set_point_in(1, Vector3(0, -0.5, 0))

func _on_connection_area_entered(area: Area3D) -> void:
	var other: Electrical = area.get_parent() as Electrical
	if other == null or other == self:
		return

	var from: Electrical
	var to: Electrical

	# if this is a producer, we always send power
	if electrical_type == Type.PRODUCER:
		from = self
		to = other
	# if this is a connector
	elif electrical_type == Type.CONNECTOR or electrical_type == Type.SWITCH:
		if other.electrical_type == Type.PRODUCER:
			from = other
			to = self
		else:
			from = self
			to = other

	# consumer will never initiate
	else:
		return

	# if we are receiving from a consumer, that shouldnt occur
	if from.electrical_type == Type.CONSUMER:
		return

	connect_electricity(from, to)

func _on_connection_area_exit(area: Area3D) -> void:
	var other: Electrical = area.get_parent() as Electrical
	if other == null:
		return

	disconnect_electricity(self, other)


func connect_electricity(a: Electrical, b: Electrical) -> void:
	if ((a in b.nodes) or (b in a.nodes)):
		return
	a.nodes.append(b)
	b.nodes.append(a)
	connect_wire(a, b)
	a.propagate_update()

func disconnect_electricity(a: Electrical, b: Electrical) -> void:
	a.nodes.erase(b)
	b.nodes.erase(a)
	disconnect_wire(a, b)
	a.propagate_update()

func connect_wire(a: Electrical, b: Electrical) -> void:
	var wire: Path3D = wire_scene.instantiate() as Path3D
	add_child(wire)

	var curve: Curve3D = Curve3D.new()
	curve.add_point(wire.to_local(a.global_position))
	curve.set_point_out(0, Vector3(0, -0.5, 0))
	curve.add_point(wire.to_local(b.global_position))
	curve.set_point_in(1, Vector3(0, -0.5, 0))
	wire.curve = curve

	a.wires_to[b] = wire
	b.wires_to[a] = wire


func disconnect_wire(a: Electrical, b: Electrical) -> void:
	if a.wires_to.has(b):
		var wire: Path3D = a.wires_to[b]
		if is_instance_valid(wire):
			wire.queue_free()
		a.wires_to.erase(b)

	b.wires_to.erase(a)

func propagate_update(visited: Dictionary[int, bool] = {}) -> void:
	if visited.has(id):
		return
	visited[id] = true

	var prev_power: bool = has_power

	update_power()
	update_labels()

	# if power changed
	if prev_power != has_power:
		set_power(has_power)

	for node: Electrical in nodes:
		node.propagate_update(visited)


func set_power(value: bool) -> void:
	var node: Node3D = get_parent()
	if node == null:
		return
	if value and node.has_method("enable"):
		node.enable()
	elif not value and node.has_method("disable"):
		node.disable()

func update_power(visited: Dictionary[int, bool] = {}) -> void:
	if visited.has(id):
		return
	visited[id] = true

	# default
	has_power = false

	# producers always have power
	if electrical_type == Type.PRODUCER:
		has_power = true
		return

	# switches: only operate if parent.on == true
	if electrical_type == Type.SWITCH:
		var parent: Node = get_parent()
		if not parent.on:
			return
		# otherwise behave like a connector

	# consumer: can receive, cannot relay
	if electrical_type == Type.CONSUMER:
		for node: Electrical in nodes:
			if node.electrical_type != Type.CONSUMER and node.has_power:
				has_power = true
				return
		return

	# connector: relay, but NEVER from consumers
	for node: Electrical in nodes:
		if node.electrical_type == Type.CONSUMER:
			continue
		node.update_power(visited)
		if node.has_power:
			has_power = true
			return


func update_labels() -> void:
	for i: int in range(nodes.size() - 1, -1, -1):
		if not is_instance_valid(nodes[i]):
			nodes.remove_at(i)

	var from_ids: Array[String] = []
	for node: Electrical in nodes:
		from_ids.append(str(node.id))

	$PowerLabel.text = "Power: " + str(has_power)
