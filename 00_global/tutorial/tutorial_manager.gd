extends Node

const POPUP_PATH = "res://00_global/tutorial/tutorial_popup.tscn"

func show_tutorial(id: String, t: String, d: String) -> void:
	print("[MANAGER] show_tutorial chamado: ", id)
	if not ResourceLoader.exists(POPUP_PATH):
		printerr("[MANAGER] Cena não encontrada: ", POPUP_PATH)
		return
	var popup = load(POPUP_PATH).instantiate()
	if popup.has_method("setup"):
		popup.setup(id, t, d)
	get_tree().root.add_child(popup)
	print("[MANAGER] Popup adicionado à árvore")
