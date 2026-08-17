extends Node

var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var sample_rate := 22050.0
var step_time := 0.0
var step := 0
var mode := "menu"

const MENU_NOTES := [110.0, 164.81, 146.83, 220.0, 196.0, 164.81, 146.83, 123.47]
const BATTLE_NOTES := [110.0, 110.0, 130.81, 146.83, 110.0, 164.81, 146.83, 98.0]

func _ready() -> void:
    generator = AudioStreamGenerator.new()
    generator.mix_rate = sample_rate
    generator.buffer_length = 0.25
    player = AudioStreamPlayer.new()
    player.stream = generator
    player.volume_db = linear_to_db(float(GameState.settings.get("music", 0.75)))
    add_child(player)
    player.play()
    playback = player.get_stream_playback()

func set_mode(new_mode: String) -> void:
    mode = new_mode
    step = 0
    step_time = 0.0

func _process(delta: float) -> void:
    step_time += delta
    if step_time > (0.28 if mode == "battle" else 0.48):
        step_time = 0.0
        step = (step + 1) % 8
    _fill_buffer()

func _fill_buffer() -> void:
    if playback == null:
        return
    var frames: int = playback.get_frames_available()
    var notes: Array = BATTLE_NOTES if mode == "battle" else MENU_NOTES
    var base: float = float(notes[step])
    for _i in range(frames):
        phase = fmod(phase + base / sample_rate, 1.0)
        var saw: float = (phase * 2.0 - 1.0) * 0.11
        var sub: float = sin(phase * TAU * 0.5) * 0.07
        var pulse: float = 0.04 if phase < 0.18 else -0.02
        var sample: float = clampf((saw + sub + pulse) * float(GameState.settings.get("music", 0.75)), -0.35, 0.35)
        playback.push_frame(Vector2(sample, sample))
