extends SceneTree

# Renders a script-driven node for a few frames and saves a PNG.
#   SHOT_SCRIPT  res:// path of a Node script to instantiate
#   SHOT_OUT     absolute path of the PNG to write
#   SHOT_FRAMES  frames to wait before capturing (default 20)

func _initialize() -> void:
	var node: Node = (load(OS.get_environment("SHOT_SCRIPT")) as GDScript).new()
	root.add_child(node)
	_run()


func _run() -> void:
	var frames := int(OS.get_environment("SHOT_FRAMES")) if OS.has_environment("SHOT_FRAMES") else 20
	for i in frames:
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
	quit()
