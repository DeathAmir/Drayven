extends Node

var music_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()
var ui_player := AudioStreamPlayer.new()

func _ready() -> void:
    add_child(music_player)
    add_child(sfx_player)
    add_child(ui_player)
    music_player.bus = "Master"
    _load_audio()

func _load_audio() -> void:
    if ResourceLoader.exists("res://assets/vendor/music/psycho_punch.ogg"):
        music_player.stream = load("res://assets/vendor/music/psycho_punch.ogg")
        music_player.volume_db = linear_to_db(float(GameState.settings.music))
        music_player.finished.connect(func(): music_player.play())
        music_player.play()
    if ResourceLoader.exists("res://assets/vendor/sfx/laser.wav"):
        sfx_player.stream = load("res://assets/vendor/sfx/laser.wav")
    if ResourceLoader.exists("res://assets/vendor/sfx/click.wav"):
        ui_player.stream = load("res://assets/vendor/sfx/click.wav")

func set_mode(_mode: String) -> void:
    if music_player.stream and not music_player.playing:
        music_player.play()

func play_shot() -> void:
    if sfx_player.stream:
        sfx_player.volume_db = linear_to_db(float(GameState.settings.sfx))
        sfx_player.play()

func play_click() -> void:
    if ui_player.stream:
        ui_player.volume_db = linear_to_db(float(GameState.settings.sfx))
        ui_player.play()
