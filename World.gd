extends Spatial

export(String, "player", "orthagonal") var camera_select setget _set_camera

func _set_camera(camera):
	camera_select = camera
	# the scene ready check is necessary since the setter can send signals before the scene is fully loaded
	if scene_ready:
		match camera:
			"player":
				# sets all properties and assets for Player View
				$CameraPivot/Camera.current = false
				$Player/Head/Camera.current = true

				$HUD.visible = true
				$Player.visible = true

				$CameraPivot.visible = false
				$CameraPivot/Arrow.visible = false
				arrow = $HUD/DirectionalArrow
				player = $Player
				rotation_offset = 270
				
				# sets arrow position
				arrow.position = $Player/Head/Camera.unproject_position($Player.translation)
				arrow.position.y = arrow.position.y - 100
				arrow_position = arrow.position
			"orthagonal":
				# sets all properties and assets for Orthagonal View
				$Player/Head/Camera.current = false
				$CameraPivot/Camera.current = true

				$HUD.visible = false
				$Player.visible = false

				$CameraPivot.visible = true
				$CameraPivot/Arrow.visible = true
				arrow = $CameraPivot/Arrow
				player = $CameraPivot
				rotation_offset = 90

				# sets arrow position
				arrow.position = $CameraPivot/Camera.unproject_position($CameraPivot.translation)

				# adjusts the initial arrow size
				orthag_arrow_adjust = 1 - ($CameraPivot/Camera.size / orthagonal_cam_max)
				orthag_arrow_adjusted = (orthag_arrow_adjust * 0.30) + 0.10

				$CameraPivot/Arrow.scale.x = orthag_arrow_adjusted
				$CameraPivot/Arrow.scale.y = orthag_arrow_adjusted
		

var orthag_arrow_adjust
var orthag_arrow_adjusted

var player_arrow_adjust
var player_arrow_adjusted

var nearest_node = null
var arrow
var arrow_position
onready var player = $Player
var rotation_offset
var scene_ready = false

func _ready():
	scene_ready = true
	_set_camera("player")

func _process(_delta):
	
	if player:
#		# sets nearest enemy, compares enemy distances to player and identifies the shortest, therefore, nearest enemy
		for node in get_tree().get_nodes_in_group("Detectable"):
			if nearest_node == null:
				nearest_node = node
			else:
				if node.translation.distance_to(player.translation) < nearest_node.translation.distance_to(player.translation):
					nearest_node = node
#
#		# uses player distance to mesh to modify arrow color
		var distance = player.translation.distance_to(nearest_node.translation)

		var distance_normalized = 1.0 / ( distance - 0 + 1.0) * 10
		var distance_clamped = clamp(distance_normalized, 0, 1)
#
		# changes arrow color per nearest node parent name
		match nearest_node.get_parent().name:
			"Enemies":
				arrow.modulate = Color(1, 1-distance_clamped, 1-distance_clamped)
			"Items":
				arrow.modulate = Color(1-distance_clamped, 1-distance_clamped, 1)
			"Resources":
				arrow.modulate = Color(1-distance_clamped, 1, 1-distance_clamped)
		
		# controls arrow rotation
		var x_diff = player.translation.x - nearest_node.translation.x
		var y_diff = player.translation.y - nearest_node.translation.y
		var z_diff = player.translation.z - nearest_node.translation.z
		
		$ViewportContainer/Viewport/Arrow/Mesh.rotation_degrees.y = rad2deg(atan2(x_diff, z_diff)) - player.rotation_degrees.y - rotation_offset
		$ViewportContainer/Viewport/Arrow/Mesh.rotation_degrees.z = rad2deg(atan2(y_diff, player.translation.distance_to(nearest_node.translation) + y_diff))
		
		# controls movement for orthagonal view
		if $CameraPivot/Camera.current:
			var forward = $CameraPivot.transform.basis.z.normalized() * 1

			if Input.is_action_pressed("forward"):
				$CameraPivot.transform.origin += -forward
			if Input.is_action_pressed("backward"):
				$CameraPivot.transform.origin += forward
			if Input.is_action_pressed("left"):
				$CameraPivot.transform.origin += forward.cross(Vector3.UP) / 1.5
			if Input.is_action_pressed("right"):
				$CameraPivot.transform.origin += -forward.cross(Vector3.UP) / 1.5

			if Input.is_action_pressed("rotate_left"):
				$CameraPivot.rotation_degrees.y -= 1

			if Input.is_action_pressed("rotate_right"):
				$CameraPivot.rotation_degrees.y += 1
				

# maximum and minimum for player camera size
var player_cam_max = 15
var player_cam_min = 1

# maximum and minimum orthagonal camera size
var orthagonal_cam_max = 30
var orthagonal_cam_min = 10

func _input(event):
	# scales arrow size per camera size
	if $Player/Head/Camera.current:
		player_arrow_adjust = 1 - ($Player/Head/Camera.translation.y / player_cam_max)
		player_arrow_adjusted = (player_arrow_adjust * 0.30) + 0.10

	else:
		orthag_arrow_adjust = 1 - ($CameraPivot/Camera.size / orthagonal_cam_max)
		orthag_arrow_adjusted = (orthag_arrow_adjust * 0.30) + 0.10

	if Input.is_action_pressed("zoom_in"):
		if $Player/Head/Camera.current:
			if $Player/Head/Camera.translation.y > player_cam_min:
				$Player/Head/Camera.translation.y -= 1
				arrow.scale.x = player_arrow_adjusted
				arrow.scale.y = player_arrow_adjusted
				
				$HUD/DirectionalArrow.position.y = arrow_position.y + 70

		else:
			if $CameraPivot/Camera.size > orthagonal_cam_min:
				$CameraPivot/Camera.size -= 1

				arrow.scale.x = orthag_arrow_adjusted
				arrow.scale.y = orthag_arrow_adjusted
				
	if Input.is_action_pressed("zoom_out"):
		if $Player/Head/Camera.current:
			if $Player/Head/Camera.translation.y < player_cam_max:
				$Player/Head/Camera.translation.y += 1
				arrow.scale.x = player_arrow_adjusted
				arrow.scale.y = player_arrow_adjusted
				
				$HUD/DirectionalArrow.position.y = arrow_position.y + 70

		else:
			if $CameraPivot/Camera.size < orthagonal_cam_max:
				$CameraPivot/Camera.size += 1

				arrow.scale.x = orthag_arrow_adjusted
				arrow.scale.y = orthag_arrow_adjusted
