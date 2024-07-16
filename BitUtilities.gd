extends Node
 # V1
func draw_line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)

func draw_point(pos: Vector3, radius = 0.05, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = sphere_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	sphere_mesh.radius = radius
	sphere_mesh.height = radius*2
	sphere_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)

func draw_square(pos: Vector3, size: Vector2, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = box_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	box_mesh.size = Vector3(size.x, size.y, 1)
	box_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)


func raycast(from: Vector3, to: Vector3):
	var space = get_viewport().world_3d.direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.hit_back_faces = true
	params.hit_from_inside = true
	var result = space.intersect_ray(params)
	return result

func physicsMove(delta, pos, vel, gravity, gravityModifier, airResitance):
	vel += gravity * gravityModifier * delta
	vel *= 1 / (1 + airResitance * delta)
	pos += vel * delta;
	return [pos, vel]

func spawnPreefab(ProjectilePreefab : PackedScene):
	var spawnedProjectile = ProjectilePreefab.instantiate()
	add_child(spawnedProjectile)
	return spawnedProjectile

func reMap(value  : float, oldMin : float, oldMax : float, newMin : float, newMax : float):
	return (value - oldMin) * (newMax - newMin) / (oldMax - oldMin) + newMin

func lerp(a: float, b: float, t: float) -> float:
	return a + t * (b - a)

func lerpColor(color_a: Color, color_b: Color, t: float) -> Color:
	var r = color_a.r + t * (color_b.r - color_a.r)
	var g = color_a.g + t * (color_b.g - color_a.g)
	var b = color_a.b + t * (color_b.b - color_a.b)
	var a = color_a.a + t * (color_b.a - color_a.a)
	return Color(r, g, b, a)
# ------------TOOLS------------
# Dont call anything below this line
# 1 -> lasts ONLY for current physics frame in ms
# >1 -> X time duration.
# <1 -> infinitly long
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	persist_ms = persist_ms/1000
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
