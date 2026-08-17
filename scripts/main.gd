extends Node2D

const PlayerScene := preload("res://scenes/Player.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const PickupScript := preload("res://scripts/pickup.gd")

var rng := RandomNumberGenerator.new()
var state := "menu"
var mode := "story"
var player
var ui := CanvasLayer.new()
var menu_root: Control
var hud_root: Control
var wave := 0
var enemies_to_spawn := 0
var spawned := 0
var spawn_timer := 0.0
var chapter := 1
var chapter_complete := false
var run_score := 0
var kills := 0
var title_label: Label
var objective_label: Label
var hp_bar: ProgressBar
var ability_bar: ProgressBar
var ammo_label: Label
var score_label: Label
var shard_label: Label
var banner_label: Label
var mobile_hint: Label

const STORY := {
    1: {"title":"CHAPTER I — BLACKOUT", "brief":"Noxara went dark in 11 seconds. Enter Sector 7 and recover the first Drayven fragment before the Null Choir reaches it.", "waves":3, "reward":"Scattergun"},
    2: {"title":"CHAPTER II — THE GLASS VEIN", "brief":"The fragment is alive. Follow its signal through the flooded transit ring and destroy the Warden carrying its twin.", "waves":3, "reward":"Iris"},
    3: {"title":"CHAPTER III — GHOST PROTOCOL", "brief":"A buried military AI has opened the city vaults. Survive the hunters, seize the rail core, and learn who started the blackout.", "waves":4, "reward":"Rail Rifle"},
    4: {"title":"CHAPTER IV — NEON REQUIEM", "brief":"The Drayven Core is a prison, not a reactor. Reach the heart of Noxara and face the Core Titan before the entity inside wakes.", "waves":4, "reward":"Nyx"}
}

func _ready() -> void:
    rng.randomize()
    _setup_inputs()
    add_child(ui)
    _build_menu()
    AudioManager.set_mode("menu")
    queue_redraw()

func _setup_inputs() -> void:
    var keys := {
        "move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S,
        "ability": KEY_Q, "reload": KEY_R, "interact": KEY_E, "next_weapon": KEY_X,
        "prev_weapon": KEY_Z, "pause": KEY_ESCAPE
    }
    for action in keys.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var ev := InputEventKey.new()
        ev.physical_keycode = keys[action]
        InputMap.action_add_event(action, ev)
    if not InputMap.has_action("shoot"):
        InputMap.add_action("shoot")
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    InputMap.action_add_event("shoot", mouse)

func _process(delta: float) -> void:
    if state != "playing":
        return
    shard_label.text = "SHARDS  %04d" % GameState.shards
    if player:
        run_score = player.score
    if enemies_to_spawn > spawned:
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            _spawn_enemy()
            spawned += 1
            spawn_timer = maxf(0.22, 0.72 - chapter * 0.08 - wave * 0.04)
    elif get_tree().get_nodes_in_group("enemies").is_empty() and not chapter_complete:
        if mode == "arena":
            _begin_wave()
        elif wave >= int(STORY[chapter].waves):
            _complete_chapter()
        else:
            _begin_wave()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720), Color("050b12"))
    for x in range(0, 1281, 64):
        draw_line(Vector2(x,0), Vector2(x,720), Color(0.16,0.35,0.43,0.09), 1.0)
    for y in range(0, 721, 64):
        draw_line(Vector2(0,y), Vector2(1280,y), Color(0.16,0.35,0.43,0.09), 1.0)
    draw_circle(Vector2(1080,120), 240.0, Color(0.29,0.13,0.52,0.09))
    draw_circle(Vector2(180,620), 280.0, Color(0.06,0.62,0.72,0.07))
    if state == "playing":
        draw_rect(Rect2(24,46,1232,650), Color(0.02,0.04,0.07,0.18), false, 2.0)

func _base_label(text: String, size: int = 20) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color("e8f9ff"))
    return l

func _button(text: String) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(310, 50)
    b.add_theme_font_size_override("font_size", 18)
    return b

func _clear_ui() -> void:
    for child in ui.get_children():
        child.queue_free()

func _build_menu() -> void:
    state = "menu"
    _clear_ui()
    AudioManager.set_mode("menu")
    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(menu_root)

    var logo := TextureRect.new()
    logo.texture = load("res://assets/ui/logo.svg")
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.position = Vector2(190, 60)
    logo.size = Vector2(900, 220)
    menu_root.add_child(logo)

    var subtitle := _base_label("A STORY-DRIVEN 2D NEON SHOOTER", 16)
    subtitle.position = Vector2(455, 250)
    menu_root.add_child(subtitle)

    var box := VBoxContainer.new()
    box.position = Vector2(485, 315)
    box.add_theme_constant_override("separation", 12)
    menu_root.add_child(box)
    var story_btn := _button("CONTINUE STORY")
    story_btn.pressed.connect(func(): _show_story_brief(GameState.story_chapter))
    box.add_child(story_btn)
    var arena_btn := _button("NEON ARENA")
    arena_btn.pressed.connect(func(): _start_game("arena", 1))
    box.add_child(arena_btn)
    var roster_btn := _button("OPERATIVES & LOADOUT")
    roster_btn.pressed.connect(_show_roster)
    box.add_child(roster_btn)
    var credits_btn := _button("CREDITS / LICENSES")
    credits_btn.pressed.connect(_show_credits)
    box.add_child(credits_btn)

    var meta := _base_label("BEST %07d     SHARDS %04d     CHAPTER %d/4" % [GameState.best_score, GameState.shards, GameState.story_chapter], 16)
    meta.position = Vector2(449, 610)
    menu_root.add_child(meta)
    var controls := _base_label("WASD • Mouse aim/fire • Q ability • R reload • Wheel/Z/X weapons   |   Mobile: left drag + right hold", 14)
    controls.position = Vector2(265, 670)
    controls.modulate = Color(0.8,0.9,1,0.7)
    menu_root.add_child(controls)

func _show_story_brief(ch: int) -> void:
    chapter = clampi(ch, 1, 4)
    _clear_ui()
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var title := _base_label(STORY[chapter].title, 34)
    title.position = Vector2(130, 125)
    root.add_child(title)
    var brief := _base_label(STORY[chapter].brief, 21)
    brief.position = Vector2(130, 205)
    brief.size = Vector2(1020, 150)
    brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(brief)
    var operative := _base_label("OPERATIVE: %s  —  %s" % [GameState.selected_character, GameState.CHARACTERS[GameState.selected_character].ability], 18)
    operative.position = Vector2(130, 390)
    root.add_child(operative)
    var start := _button("DEPLOY")
    start.position = Vector2(130, 500)
    start.pressed.connect(func(): _start_game("story", chapter))
    root.add_child(start)
    var back := _button("BACK")
    back.position = Vector2(475, 500)
    back.pressed.connect(_build_menu)
    root.add_child(back)

func _show_roster() -> void:
    _clear_ui()
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var title := _base_label("OPERATIVES", 34)
    title.position = Vector2(90,60)
    root.add_child(title)
    var x := 90.0
    for char_name in GameState.CHARACTERS.keys():
        var data: Dictionary = GameState.CHARACTERS[char_name]
        var card := VBoxContainer.new()
        card.position = Vector2(x,145)
        card.custom_minimum_size = Vector2(250,300)
        root.add_child(card)
        var n := _base_label(char_name, 28)
        n.add_theme_color_override("font_color", data.color)
        card.add_child(n)
        var status := _base_label("UNLOCKED" if char_name in GameState.unlocked_characters else "LOCKED", 14)
        card.add_child(status)
        var ability := _base_label(str(data.ability), 17)
        card.add_child(ability)
        var desc := _base_label(str(data.desc), 14)
        desc.custom_minimum_size = Vector2(230,100)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.add_child(desc)
        var select := _button("SELECT" if char_name in GameState.unlocked_characters else "LOCKED")
        select.custom_minimum_size = Vector2(225,42)
        select.disabled = char_name not in GameState.unlocked_characters
        select.pressed.connect(func(name = char_name): GameState.selected_character = name; GameState.save(); _show_roster())
        card.add_child(select)
        x += 285.0
    var weapons := _base_label("UNLOCKED: " + ", ".join(GameState.unlocked_weapons), 16)
    weapons.position = Vector2(90,520)
    weapons.size = Vector2(1080,70)
    weapons.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(weapons)
    var back := _button("BACK")
    back.position = Vector2(90,625)
    back.pressed.connect(_build_menu)
    root.add_child(back)

func _show_credits() -> void:
    _clear_ui()
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var title := _base_label("CREDITS & LICENSES", 34)
    title.position = Vector2(100,70)
    root.add_child(title)
    var body := _base_label("DRAYVEN: NEON REQUIEM\n\nGame design, code, vector art and procedural music system: original project assets.\nNo third-party samples are bundled. The procedural score is synthesized at runtime from original note patterns and waveforms.\nEngine: Godot Engine 4.6.2 (MIT License).\n\nProject source license: MIT unless a file states otherwise.\nSee LICENSE and THIRD_PARTY_NOTICES.md in the repository.", 18)
    body.position = Vector2(100,150)
    body.size = Vector2(1050,360)
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(body)
    var back := _button("BACK")
    back.position = Vector2(100,610)
    back.pressed.connect(_build_menu)
    root.add_child(back)

func _start_game(new_mode: String, start_chapter: int) -> void:
    mode = new_mode
    chapter = start_chapter
    state = "playing"
    chapter_complete = false
    wave = 0
    spawned = 0
    enemies_to_spawn = 0
    kills = 0
    _clear_gameplay_nodes()
    _clear_ui()
    _build_hud()
    player = PlayerScene.instantiate()
    player.global_position = Vector2(640,380)
    add_child(player)
    player.health_changed.connect(_on_health)
    player.ammo_changed.connect(_on_ammo)
    player.score_changed.connect(_on_score)
    player.ability_changed.connect(_on_ability)
    player.died.connect(_on_player_died)
    _on_health(player.hp, player.max_hp)
    _on_ammo(player.ammo, int(GameState.WEAPONS[player.weapon_name].mag), player.weapon_name)
    AudioManager.set_mode("battle")
    _begin_wave()

func _build_hud() -> void:
    hud_root = Control.new()
    hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(hud_root)
    title_label = _base_label("DRAYVEN // %s" % ("STORY" if mode == "story" else "ARENA"), 17)
    title_label.position = Vector2(32,14)
    hud_root.add_child(title_label)
    hp_bar = ProgressBar.new(); hp_bar.position = Vector2(32,650); hp_bar.size = Vector2(330,24); hp_bar.show_percentage = false
    hud_root.add_child(hp_bar)
    ability_bar = ProgressBar.new(); ability_bar.position = Vector2(32,680); ability_bar.size = Vector2(220,10); ability_bar.show_percentage = false
    hud_root.add_child(ability_bar)
    ammo_label = _base_label("", 20); ammo_label.position = Vector2(1000,650); ammo_label.size = Vector2(240,40); ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hud_root.add_child(ammo_label)
    score_label = _base_label("SCORE 0000000", 17); score_label.position = Vector2(1010,20)
    hud_root.add_child(score_label)
    shard_label = _base_label("SHARDS %04d" % GameState.shards, 15); shard_label.position = Vector2(1010,45)
    hud_root.add_child(shard_label)
    objective_label = _base_label("", 17); objective_label.position = Vector2(32,48); objective_label.size = Vector2(800,40)
    hud_root.add_child(objective_label)
    banner_label = _base_label("", 30); banner_label.position = Vector2(380,95); banner_label.size = Vector2(520,60); banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud_root.add_child(banner_label)
    mobile_hint = _base_label("◉ LEFT DRAG: MOVE     ◉ RIGHT HOLD: AIM/FIRE", 12); mobile_hint.position = Vector2(465,690); mobile_hint.modulate = Color(0.8,0.9,1,0.45)
    hud_root.add_child(mobile_hint)
    var weapon_btn := Button.new(); weapon_btn.text = "WEAPON"; weapon_btn.position = Vector2(620,646); weapon_btn.size = Vector2(108,42); weapon_btn.pressed.connect(func(): if player: player.cycle_weapon(1))
    hud_root.add_child(weapon_btn)
    var reload_btn := Button.new(); reload_btn.text = "RELOAD"; reload_btn.position = Vector2(738,646); reload_btn.size = Vector2(108,42); reload_btn.pressed.connect(func(): if player: player.reload())
    hud_root.add_child(reload_btn)
    var ability_btn := Button.new(); ability_btn.text = "ABILITY"; ability_btn.position = Vector2(856,646); ability_btn.size = Vector2(118,42); ability_btn.pressed.connect(func(): if player: player.use_ability())
    hud_root.add_child(ability_btn)

func _begin_wave() -> void:
    wave += 1
    spawned = 0
    var base := 5 + wave * 3 + (chapter - 1) * 2
    enemies_to_spawn = base if mode == "story" else 5 + wave * 4
    if mode == "story" and chapter == 4 and wave == int(STORY[chapter].waves):
        enemies_to_spawn = 1
    spawn_timer = 0.3
    objective_label.text = ("CHAPTER %d  //  WAVE %d/%d" % [chapter, wave, int(STORY[chapter].waves)]) if mode == "story" else ("ARENA WAVE %d" % wave)
    _flash_banner("WAVE %02d" % wave)

func _spawn_enemy() -> void:
    var enemy = EnemyScene.instantiate()
    var pos := _random_edge_position()
    enemy.global_position = pos
    add_child(enemy)
    if mode == "story" and chapter == 4 and wave == int(STORY[chapter].waves):
        enemy.setup("core_titan", 1.0, true, true)
        _flash_banner("CORE TITAN")
        return
    var roll := rng.randf()
    var kind := "drone"
    if wave >= 2 and roll > 0.45: kind = "stalker"
    if wave >= 3 and roll > 0.72: kind = "brute"
    if chapter >= 2 and wave >= 3 and roll > 0.9: kind = "warden"
    var elite := wave > 2 and rng.randf() < minf(0.08 + wave * 0.018, 0.28)
    var difficulty := 1.0 + (chapter - 1) * 0.16 + (wave - 1) * 0.08
    enemy.setup(kind, difficulty, elite, false)
    enemy.killed.connect(_on_enemy_killed)

func _random_edge_position() -> Vector2:
    var side := rng.randi_range(0,3)
    match side:
        0: return Vector2(rng.randf_range(40,1240), 80)
        1: return Vector2(rng.randf_range(40,1240), 660)
        2: return Vector2(50, rng.randf_range(90,650))
        _: return Vector2(1230, rng.randf_range(90,650))

func _on_enemy_killed(_points: int, pos: Vector2) -> void:
    kills += 1
    if rng.randf() < 0.28:
        var pickup := PickupScript.new()
        pickup.setup("shard", 1 if rng.randf() < 0.85 else 3)
        pickup.global_position = pos
        add_child(pickup)
    elif rng.randf() < 0.10:
        var med := PickupScript.new()
        med.setup("heal", 22)
        med.global_position = pos
        add_child(med)

func _complete_chapter() -> void:
    chapter_complete = true
    if not player:
        return
    player.can_control = false
    var reward := str(STORY[chapter].reward)
    if reward in GameState.CHARACTERS:
        GameState.unlock_character(reward)
    else:
        GameState.unlock_weapon(reward)
    GameState.add_shards(20 + chapter * 15)
    if chapter < 4:
        GameState.story_chapter = max(GameState.story_chapter, chapter + 1)
    GameState.best_score = maxi(GameState.best_score, player.score)
    GameState.save()
    _show_result(true, "CHAPTER CLEAR", "Reward unlocked: %s" % reward)

func _on_player_died() -> void:
    if player:
        GameState.best_score = maxi(GameState.best_score, player.score)
        GameState.save()
    _show_result(false, "OPERATIVE DOWN", "The city remembers every failed run. Re-arm and return.")

func _show_result(victory: bool, heading: String, text: String) -> void:
    state = "result"
    AudioManager.set_mode("menu")
    var panel := ColorRect.new()
    panel.color = Color(0.015,0.025,0.04,0.94)
    panel.position = Vector2(330,170)
    panel.size = Vector2(620,380)
    ui.add_child(panel)
    var h := _base_label(heading, 36); h.position = Vector2(65,50); h.size = Vector2(490,50); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(h)
    var t := _base_label(text, 18); t.position = Vector2(65,120); t.size = Vector2(490,80); t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(t)
    var stats := _base_label("SCORE %07d   •   KILLS %d   •   SHARDS %d" % [run_score, kills, GameState.shards], 16); stats.position = Vector2(65,210); stats.size = Vector2(490,40); stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(stats)
    var retry := _button("NEXT CHAPTER" if victory and chapter < 4 else "PLAY AGAIN")
    retry.custom_minimum_size = Vector2(225,46); retry.position = Vector2(65,285)
    retry.pressed.connect(func():
        if victory and chapter < 4: _show_story_brief(chapter + 1)
        else: _start_game(mode, chapter)
    )
    panel.add_child(retry)
    var menu := _button("MAIN MENU"); menu.custom_minimum_size = Vector2(225,46); menu.position = Vector2(330,285); menu.pressed.connect(_return_to_menu)
    panel.add_child(menu)

func _return_to_menu() -> void:
    _clear_gameplay_nodes()
    _build_menu()

func _clear_gameplay_nodes() -> void:
    for n in get_children():
        if n == ui:
            continue
        if n.is_in_group("player") or n.is_in_group("enemies") or n is Area2D:
            n.queue_free()
    player = null

func _flash_banner(text: String) -> void:
    if not banner_label:
        return
    banner_label.text = text
    banner_label.modulate = Color(1,1,1,1)
    var tween := create_tween()
    tween.tween_interval(0.7)
    tween.tween_property(banner_label, "modulate:a", 0.0, 0.6)

func _on_health(value: float, maximum: float) -> void:
    if hp_bar:
        hp_bar.max_value = maximum
        hp_bar.value = value

func _on_ammo(value: int, maximum: int, weapon: String) -> void:
    if ammo_label:
        ammo_label.text = "%s\n%02d / %02d" % [weapon.to_upper(), value, maximum]

func _on_score(value: int) -> void:
    run_score = value
    if score_label:
        score_label.text = "SCORE %07d" % value

func _on_ability(value: float, maximum: float) -> void:
    if ability_bar:
        ability_bar.max_value = maximum
        ability_bar.value = value
