extends Node3D

@export var timeToLive = float()
@export var airResitance = float()
@export var bullet_gravity = float()
@export var gravityModifier = Vector3()

@export var fired = false
@export var bullet_velocity = Vector3()
@export var bullet_mass = float()
@export var bullet_diameter = float()
@export var demarreConst = float()

@export var maxShrapnel = float()

@export var Tracer : bool


# Public var save
var startVelocity
var thickness = 0















@export var TrailMesh : Node3D
@export var SpinEffect : float

@export var distancemultiplier : float
@export var trailSizeFade : float

@export var StartColor : Color
@export var EndColor : Color
@export var ColorSpeed : float
@export var ColorFadeOut : float

@export var material : StandardMaterial3D
var WidthTrail = 0
var EmmisionColor = 0

var spin = 0
var cameras

var timeDistanceFade = 0
var timeColorChange = 0
var prevPos : Vector3
var rng = RandomNumberGenerator.new()
func _ready():
	startVelocity = bullet_velocity
	prevPos = global_position

	if Tracer:
		cameras = get_viewport().get_camera_3d()
		EmmisionColor = StartColor
func _physics_process(delta):
	if startVelocity == Vector3.ZERO:
		startVelocity = bullet_velocity
	timeToLive -= delta
	if timeToLive <= 0:
		queue_free() 
	if fired:

		# Physics movement
		var PhysicsMovementUpdate = BitUtilities.physicsMove(delta, global_position, bullet_velocity, bullet_gravity, gravityModifier, airResitance)
		global_position = PhysicsMovementUpdate[0]
		bullet_velocity = PhysicsMovementUpdate[1]


		var ray_moveCheck = BitUtilities.raycast(prevPos, global_position)
		if ray_moveCheck:
#DEBUG
			BitUtilities.draw_line(global_position, ray_moveCheck.position, Color.GOLD,200)
			BitUtilities.draw_point(ray_moveCheck.position,0.01,Color.GOLD,200)

			var Ray_Thickness = BitUtilities.raycast(ray_moveCheck.position - ray_moveCheck.normal * 0.00001, ray_moveCheck.position - ray_moveCheck.normal * 0.5)
#DEBUG
			BitUtilities.draw_line(ray_moveCheck.position - ray_moveCheck.normal * 0.00001, ray_moveCheck.position - ray_moveCheck.normal * 0.5, Color.GREEN,200)
			#BitUtilities.draw_point(ray_moveCheck.position - ray_moveCheck.normal * 0.001, 0.01, Color.GREEN,2000)

			var angle = rad_to_deg(acos(bullet_velocity.normalized().dot(ray_moveCheck.normal.normalized())))-90
			if Ray_Thickness:
				BitUtilities.draw_line(ray_moveCheck.position, Ray_Thickness.position, Color.RED,200)
				BitUtilities.draw_point(Ray_Thickness.position, 0.01, Color.RED,200)

				thickness = ray_moveCheck.position.distance_to(Ray_Thickness.position)
				# calculate if bullet will penetrate the plate or not using DeMarre formula
				# if bullet does not penetrate, it will calculate if it will ricoshet
				# else destroy the bullet if it did not penetrate or ricoshet
				var PenetrationValue = DeMarre(bullet_mass*0.001, bullet_diameter*0.001, bullet_velocity.length()*0.5, 90-angle, demarreConst, thickness*100)*100
				print(PenetrationValue, " ", thickness*100)
				if (PenetrationValue >= thickness*100):
					prevPos = Ray_Thickness.position - Ray_Thickness.normal * 0.00001
					global_position = Ray_Thickness.position - Ray_Thickness.normal * 0.00001
					bullet_velocity = bullet_velocity.normalized() * (bullet_velocity.length() * 0.5 * BitUtilities.reMap(Vector2(PenetrationValue,thickness*100).normalized().x, 0.707,1,0,1));
					bullet_velocity = (Ray_Thickness.normal*-0.2 + bullet_velocity.normalized() * 0.5) * bullet_velocity.length()
					var bulVelLen = bullet_velocity.length()*0.5
					bullet_velocity = bullet_velocity - Vector3(randf_range(-bulVelLen,bulVelLen),randf_range(-bulVelLen,bulVelLen),randf_range(-bulVelLen,bulVelLen))*0.5
					# Shrapnell
					if (maxShrapnel != 0):

						for i in range(0,BitUtilities.reMap(bullet_velocity.length()*thickness*2, 0, startVelocity.length(), 0, maxShrapnel)):
							#pass
							#pass
							var NewShrapnel = BitUtilities.spawnPreefab(load(str("res://Prefabs/bullets/5_56x45.tscn")))
							var Shrapnel : Node3D = NewShrapnel.get_node("./")
							# set bullet position and velocity with spread
							Shrapnel.global_position = Ray_Thickness.position - Ray_Thickness.normal * 0.01
							Shrapnel.prevPos = Ray_Thickness.position - Ray_Thickness.normal * 0.01
							var randomizer = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))
							Shrapnel.bullet_velocity = bullet_velocity*0.3 + randomizer*bullet_velocity.length()*BitUtilities.reMap(Vector2(PenetrationValue,thickness*100).normalized().x, 0.707,1,0,1)*0.1
							

				elif (atan((bullet_velocity.length()*bullet_velocity.length()) / (bullet_gravity*gravityModifier.length()*(bullet_mass*demarreConst*0.6))) * 57.296) < 90-angle:
					print("Ricoshet")
					prevPos = ray_moveCheck.position + ray_moveCheck.normal * 0.00001
					global_position = ray_moveCheck.position + ray_moveCheck.normal * 0.00001
					bullet_velocity = bullet_velocity.reflect(ray_moveCheck.normal)*-1
					bullet_velocity = bullet_velocity.normalized() * (bullet_velocity.length() * BitUtilities.reMap(90-angle, 0,90,0,0.4));
					print("speeed: ",bullet_velocity.length())
					
				else:
					queue_free()
			elif (atan((bullet_velocity.length()*bullet_velocity.length()) / (bullet_gravity*gravityModifier.length()*(bullet_mass*demarreConst*0.6))) * 57.296) < 90-angle:
				print("Ricoshet")
				prevPos = ray_moveCheck.position + ray_moveCheck.normal * 0.00001
				global_position = ray_moveCheck.position + ray_moveCheck.normal * 0.00001
				bullet_velocity = bullet_velocity.reflect(ray_moveCheck.normal)*-1
				bullet_velocity = bullet_velocity.normalized() * (bullet_velocity.length() * BitUtilities.reMap(90-angle, 0,90,0,0.4));
				print("speeed: ",bullet_velocity.length())
			else:
				queue_free()





	if Tracer:
		spin = spin + SpinEffect * delta
		var direction = global_position - prevPos
		TrailMesh.global_position = (prevPos + global_position) / 2.0

		if cameras:
			var collorFadeOut = 0

			var WidthTrailDistance = cameras.global_position.distance_to(TrailMesh.global_position) * distancemultiplier
			timeDistanceFade = timeDistanceFade + delta * trailSizeFade
			if(timeDistanceFade >= 1):
				pass
			else:
				WidthTrail = BitUtilities.lerp(WidthTrailDistance,0.00001,timeDistanceFade)

			var collorDifference = (EndColor - EmmisionColor)/2
			if ColorFadeOut != 0:
				collorFadeOut = abs(collorDifference.r+collorDifference.g+collorDifference.b)/3*ColorFadeOut
				timeColorChange = timeColorChange + delta * ColorSpeed * collorFadeOut
			else:
				timeColorChange = timeColorChange + delta * ColorSpeed
			if(timeColorChange >= 1):
				pass
			else:
				EmmisionColor = BitUtilities.lerpColor(StartColor, EndColor, timeColorChange)

			if prevPos != Vector3(0,0,0):
				TrailMesh.scale = Vector3(WidthTrail, WidthTrail, direction.length())
				material.albedo_color = EmmisionColor
				material.emission = EmmisionColor


		else:
			TrailMesh.scale = Vector3(1, 1, direction.length())
		#BitUtilities.draw_line(prevPos, MainBullet.global_position, Color.WHITE, 1/delta)
		
		TrailMesh.look_at(global_transform.origin + direction, Vector3(0,0,1))
		TrailMesh.rotation_degrees.z = 0
		TrailMesh.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		
		TrailMesh.rotate_object_local(Vector3.UP, deg_to_rad(spin))




	prevPos = global_position


func DeMarre(mass : float, Diameter : float, velocity : float, angle : float, demarreConst : float, thickness : float) -> float:
	var pen = pow((mass * pow(velocity * cos(0.0174532925199 * angle), 2)) / (pow(Diameter / 100, 3) * (pow(demarreConst, 2) * pow(Diameter / 100, 0.1 * -1))), 1 / thickness) * Diameter / 100
	return pen
	
func fire(velocity : Vector3):
	bullet_velocity = velocity
	fired = true
