extends Node2D

const PlayerScene := preload("res://scenes/Player.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const BG := preload("res://assets/vendor/backgrounds/darkPurple.png")
const FLAG := preload("res://assets/vendor/items/flagBlue.png")
const CHEST := preload("res://assets/vendor/items/chest.png")
const CHEST_OPEN := preload("res://assets/vendor/items/chest_open.png")
const BTN_NORMAL := preload("res://assets/vendor/ui/buttonBlue.png")
const BTN_PRESSED := preload("res://assets/vendor/ui/buttonBlue_pressed.png")
const TOUCH_BASE := preload("res://assets/vendor/ui/flatDark00.png")
const TOUCH_FIRE := preload("res://assets/vendor/ui/flatDark06.png")
const TOUCH_ACTION := preload("res://assets/vendor/ui/flatDark07.png")
const TOUCH_SMALL := preload("res://assets/vendor/ui/flatDark08.png")
const FONT := preload("res://assets/vendor/fonts/Vazirmatn-RD-Regular.ttf")

var ui := CanvasLayer.new()
var world_ui := CanvasLayer.new()
var state := "menu"
var player
var current_stage := 1
var level: Dictionary
var spawned := 0
var spawn_timer := 0.0
var flags_done := 0
var flag_hold := 0.0
var flag_sprite: Sprite2D
var chest_sprite: Sprite2D
var chest_active := false
var stage_score := 0
var objective_label: Label
var stage_label: Label
var hp_bar: ProgressBar
var ability_bar: ProgressBar
var ammo_label: Label
var score_label: Label
var shard_label: Label
var selected_stage_label: Label
var joystick_knob: TextureRect
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var aim_touch := -1
var boss_spawned := false

const FLAG_POSITIONS := [
    Vector2(180,150), Vector2(1080,150), Vector2(180,550), Vector2(1080,550),
    Vector2(640,125), Vector2(640,575), Vector2(325,350), Vector2(955,350)
]

func _ready() -> void:
    _setup_inputs()
    add_child(world_ui)
    add_child(ui)
    _build_background()
    _build_menu()

func _build_background() -> void:
    var bg := TextureRect.new()
    bg.texture = BG
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_TILE
    bg.position = Vector2.ZERO
    bg.size = Vector2(1280,720)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    world_ui.add_child(bg)

func _setup_inputs() -> void:
    var keys := {"move_left":KEY_A,"move_right":KEY_D,"move_up":KEY_W,"move_down":KEY_S,"ability":KEY_Q,"reload":KEY_R,"next_weapon":KEY_X}
    for action in keys:
        if not InputMap.has_action(action): InputMap.add_action(action)
        var ev := InputEventKey.new(); ev.physical_keycode = keys[action]; InputMap.action_add_event(action, ev)
    if not InputMap.has_action("shoot"): InputMap.add_action("shoot")
    var mb := InputEventMouseButton.new(); mb.button_index = MOUSE_BUTTON_LEFT; InputMap.action_add_event("shoot", mb)

func _label(text: String, size: int = 22) -> Label:
    var l := Label.new(); l.text = text; l.add_theme_font_override("font", FONT); l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color("f5fbff")); l.layout_direction = Control.LAYOUT_DIRECTION_RTL
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    return l

func _texture_button(text: String, size := Vector2(320,72)) -> Control:
    var wrap := Control.new(); wrap.custom_minimum_size = size; wrap.size = size
    var b := TextureButton.new(); b.texture_normal = BTN_NORMAL; b.texture_pressed = BTN_PRESSED; b.ignore_texture_size = true; b.stretch_mode = TextureButton.STRETCH_SCALE
    b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); b.name = "Button"; wrap.add_child(b)
    var lab := _label(text, 24); lab.mouse_filter = Control.MOUSE_FILTER_IGNORE; lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.add_child(lab)
    return wrap

func _clear_ui() -> void:
    for c in ui.get_children(): c.queue_free()

func _build_menu() -> void:
    state = "menu"; _clear_game(); _clear_ui(); AudioManager.set_mode("menu")
    var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.layout_direction = Control.LAYOUT_DIRECTION_RTL; ui.add_child(root)
    var title := _label("DRAYVEN // درایون", 54); title.position = Vector2(390,72); title.size = Vector2(800,80); root.add_child(title)
    var sub := _label("شوتر دوبعدی داستانی • تصرف پرچم • صندوق جایزه • ۳۰۰ مرحله", 21); sub.position = Vector2(320,150); sub.size = Vector2(870,48); root.add_child(sub)
    var status := _label("بالاترین مرحله: %d / 300     شارد: %d     رکورد: %d" % [GameState.highest_stage, GameState.shards, GameState.best_score], 20)
    status.position = Vector2(300,205); status.size = Vector2(890,44); root.add_child(status)
    var play := _texture_button("▶  بازی", Vector2(390,86)); play.position = Vector2(760,290); root.add_child(play); play.get_node("Button").pressed.connect(_show_stage_select)
    var loadout := _texture_button("کاراکتر و سلاح", Vector2(390,72)); loadout.position = Vector2(760,392); root.add_child(loadout); loadout.get_node("Button").pressed.connect(_show_loadout)
    var licenses := _texture_button("مجوزها و منابع", Vector2(390,72)); licenses.position = Vector2(760,480); root.add_child(licenses); licenses.get_node("Button").pressed.connect(_show_licenses)
    var story := _label("شهر نوکسارا سقوط کرده؛ شبکه‌ی درایون با ۱۲ دژ و ۳۰۰ مأموریت کنترل شهر را گرفته. هر پرچم یک قفل امنیتی را می‌شکند. همه‌ی پرچم‌ها را تصرف کن، صندوق فرماندهی را باز کن و به قلب درایون برس.", 22)
    story.position = Vector2(80,290); story.size = Vector2(590,250); story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; root.add_child(story)
    if GameState.save_tampered:
        var warn := _label("ذخیره قبلی معتبر نبود و بارگذاری نشد.", 16); warn.position = Vector2(80,610); warn.size = Vector2(600,35); root.add_child(warn)

func _show_stage_select() -> void:
    _clear_ui(); current_stage = clampi(GameState.selected_stage,1,GameState.highest_stage)
    var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.layout_direction = Control.LAYOUT_DIRECTION_RTL; ui.add_child(root)
    var title := _label("انتخاب مرحله", 42); title.position = Vector2(780,70); title.size=Vector2(390,60); root.add_child(title)
    selected_stage_label = _label("", 27); selected_stage_label.position=Vector2(600,180); selected_stage_label.size=Vector2(570,160); selected_stage_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(selected_stage_label)
    var prev := _texture_button("◀ قبلی",Vector2(220,65)); prev.position=Vector2(680,370); root.add_child(prev); prev.get_node("Button").pressed.connect(func(): _change_stage(-1))
    var next := _texture_button("بعدی ▶",Vector2(220,65)); next.position=Vector2(930,370); root.add_child(next); next.get_node("Button").pressed.connect(func(): _change_stage(1))
    var start := _texture_button("شروع مأموریت",Vector2(470,82)); start.position=Vector2(680,470); root.add_child(start); start.get_node("Button").pressed.connect(func(): _start_stage(current_stage))
    var back := _texture_button("بازگشت",Vector2(260,60)); back.position=Vector2(80,600); root.add_child(back); back.get_node("Button").pressed.connect(_build_menu)
    _refresh_stage_text()

func _change_stage(delta: int) -> void:
    current_stage = clampi(current_stage + delta, 1, GameState.highest_stage)
    GameState.selected_stage = current_stage; GameState.save(); AudioManager.play_click(); _refresh_stage_text()

func _refresh_stage_text() -> void:
    var d := LevelCatalog.get_level(current_stage)
    selected_stage_label.text = "%s\nبخش %d: %s\nپرچم: %d  •  دشمن: %d  •  جایزه: %d شارد (%s)\n%s" % [d.title,d.sector,d.sector_name,d.flags,d.enemy_count,d.reward,d.reward_tier,d.story]

func _show_loadout() -> void:
    _clear_ui(); var root:=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.layout_direction=Control.LAYOUT_DIRECTION_RTL; ui.add_child(root)
    var title:=_label("لوداوت",40); title.position=Vector2(950,55); title.size=Vector2(220,60); root.add_child(title)
    var y:=145.0
    for name in GameState.CHARACTERS.keys():
        var unlocked := name in GameState.unlocked_characters
        var c := _texture_button(("✓ " if GameState.selected_character==name else "") + str(GameState.CHARACTERS[name].fa) + ("" if unlocked else " — قفل"),Vector2(510,62)); c.position=Vector2(650,y); root.add_child(c)
        c.get_node("Button").disabled = not unlocked
        c.get_node("Button").pressed.connect(func(n=name): GameState.selected_character=n; GameState.save(); _show_loadout())
        y += 75.0
    var weapons:=_label("سلاح‌های باز: " + "، ".join(GameState.unlocked_weapons),20); weapons.position=Vector2(80,175); weapons.size=Vector2(490,200); weapons.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(weapons)
    var back:=_texture_button("بازگشت",Vector2(260,60)); back.position=Vector2(80,600); root.add_child(back); back.get_node("Button").pressed.connect(_build_menu)

func _show_licenses() -> void:
    _clear_ui(); var root:=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.layout_direction=Control.LAYOUT_DIRECTION_RTL; ui.add_child(root)
    var title:=_label("مجوزها",40); title.position=Vector2(950,50); title.size=Vector2(220,60); root.add_child(title)
    var body:=_label("گرافیک‌های Kenney: CC0 1.0\nکاراکتر Top Down Man With Gun: CC0 — 2021 Piga Software\nصندوق brandav: CC0\nموسیقی Psycho Punch از KiluaBoy: CC0\nافکت Laser و Click از frosty ham: CC0\nفونت Vazirmatn: SIL Open Font License 1.1\nGodot Engine: MIT\n\nمتن کامل مجوزها و URL دقیق هر فایل در پوشه licenses و ASSET_SOURCES.md موجود است.",20)
    body.position=Vector2(180,150); body.size=Vector2(980,380); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(body)
    var back:=_texture_button("بازگشت",Vector2(260,60)); back.position=Vector2(80,600); root.add_child(back); back.get_node("Button").pressed.connect(_build_menu)

func _start_stage(stage_id: int) -> void:
    state="playing"; current_stage=stage_id; level=LevelCatalog.get_level(stage_id); spawned=0; flags_done=0; flag_hold=0.0; chest_active=false; stage_score=0; boss_spawned=false
    _clear_game(); _clear_ui(); _build_hud()
    player=PlayerScene.instantiate(); player.global_position=Vector2(640,390); add_child(player)
    player.health_changed.connect(func(v,m): hp_bar.max_value=m; hp_bar.value=v)
    player.ammo_changed.connect(func(v,m,w): ammo_label.text="%s  %d/%d" % [GameState.WEAPONS[w].fa,v,m])
    player.score_changed.connect(func(v): stage_score=v; score_label.text="امتیاز %07d" % v)
    player.ability_changed.connect(func(v,m): ability_bar.max_value=m; ability_bar.value=v)
    player.died.connect(_on_defeat)
    _spawn_flag(); AudioManager.set_mode("battle")

func _build_hud() -> void:
    var root:=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.layout_direction=Control.LAYOUT_DIRECTION_RTL; ui.add_child(root)
    stage_label=_label("مرحله %d / 300 — %s" % [current_stage,level.sector_name],19); stage_label.position=Vector2(850,15); stage_label.size=Vector2(390,35); root.add_child(stage_label)
    objective_label=_label("",19); objective_label.position=Vector2(360,16); objective_label.size=Vector2(470,48); root.add_child(objective_label)
    hp_bar=ProgressBar.new(); hp_bar.position=Vector2(28,620); hp_bar.size=Vector2(310,25); hp_bar.show_percentage=false; root.add_child(hp_bar)
    ability_bar=ProgressBar.new(); ability_bar.position=Vector2(28,654); ability_bar.size=Vector2(220,12); ability_bar.show_percentage=false; root.add_child(ability_bar)
    ammo_label=_label("",18); ammo_label.position=Vector2(940,610); ammo_label.size=Vector2(300,42); root.add_child(ammo_label)
    score_label=_label("امتیاز 0000000",17); score_label.position=Vector2(980,55); score_label.size=Vector2(260,34); root.add_child(score_label)
    shard_label=_label("شارد %d" % GameState.shards,16); shard_label.position=Vector2(980,88); shard_label.size=Vector2(260,30); root.add_child(shard_label)
    _build_touch_controls(root); _update_objective()

func _touch_button(texture: Texture2D, pos: Vector2, size: Vector2) -> TextureButton:
    var b:=TextureButton.new(); b.texture_normal=texture; b.ignore_texture_size=true; b.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED; b.position=pos; b.size=size; return b

func _build_touch_controls(root: Control) -> void:
    var base:=TextureRect.new(); base.texture=TOUCH_BASE; base.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; base.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; base.position=Vector2(28,475); base.size=Vector2(145,145); base.modulate=Color(1,1,1,0.72); base.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(base)
    joystick_knob=TextureRect.new(); joystick_knob.texture=TOUCH_SMALL; joystick_knob.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; joystick_knob.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; joystick_knob.position=Vector2(73,520); joystick_knob.size=Vector2(55,55); joystick_knob.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(joystick_knob); joystick_origin=Vector2(100,547)
    var fire:=_touch_button(TOUCH_FIRE,Vector2(1090,490),Vector2(145,145)); root.add_child(fire); fire.button_down.connect(func(): if player: player.set_touch_fire(true)); fire.button_up.connect(func(): if player: player.set_touch_fire(false))
    var ability:=_touch_button(TOUCH_ACTION,Vector2(940,535),Vector2(105,105)); root.add_child(ability); ability.pressed.connect(func(): if player: player.use_ability())
    var reload:=_touch_button(TOUCH_SMALL,Vector2(835,565),Vector2(82,82)); root.add_child(reload); reload.pressed.connect(func(): if player: player.reload())
    var weapon:=_touch_button(TOUCH_SMALL,Vector2(740,565),Vector2(82,82)); root.add_child(weapon); weapon.pressed.connect(func(): if player: player.cycle_weapon(1))

func _input(event: InputEvent) -> void:
    if state != "playing" or not player: return
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < 220 and event.position.y > 430 and joystick_touch == -1:
            joystick_touch=event.index; _update_joystick(event.position); get_viewport().set_input_as_handled()
        elif not event.pressed and event.index == joystick_touch:
            joystick_touch=-1; player.set_touch_move(Vector2.ZERO); joystick_knob.position=Vector2(73,520); get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == joystick_touch:
        _update_joystick(event.position); get_viewport().set_input_as_handled()

func _update_joystick(p: Vector2) -> void:
    var delta:=(p-joystick_origin).limit_length(58.0); player.set_touch_move(delta/58.0); joystick_knob.position=joystick_origin+delta-Vector2(27.5,27.5)

func _process(delta: float) -> void:
    if state != "playing" or not is_instance_valid(player): return
    shard_label.text="شارد %d" % GameState.shards
    if spawned < int(level.enemy_count):
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            _spawn_enemy(false); spawned += 1; spawn_timer=float(level.spawn_delay)
    elif bool(level.boss) and not boss_spawned:
        _spawn_enemy(true)
        boss_spawned = true
    if flag_sprite and is_instance_valid(flag_sprite):
        if player.global_position.distance_to(flag_sprite.global_position) < 62.0:
            flag_hold += delta
            objective_label.text="در حال تصرف... %d%%" % int(clampf(flag_hold/1.15,0,1)*100.0)
            if flag_hold >= 1.15: _capture_flag()
        else:
            flag_hold=maxf(0.0,flag_hold-delta*2.5); _update_objective()
    elif chest_active and chest_sprite and player.global_position.distance_to(chest_sprite.global_position) < 68.0:
        _open_chest()

func _spawn_flag() -> void:
    if flag_sprite and is_instance_valid(flag_sprite): flag_sprite.queue_free()
    flag_sprite=Sprite2D.new(); flag_sprite.texture=FLAG; flag_sprite.scale=Vector2(0.72,0.72)
    var idx:=(current_stage*3+flags_done*2)%FLAG_POSITIONS.size(); flag_sprite.global_position=FLAG_POSITIONS[idx]; add_child(flag_sprite); flag_hold=0.0; _update_objective()

func _capture_flag() -> void:
    flags_done += 1; AudioManager.play_click(); flag_sprite.queue_free(); flag_sprite=null; flag_hold=0.0
    if flags_done >= int(level.flags): _spawn_chest()
    else: _spawn_flag()

func _spawn_chest() -> void:
    chest_active=true; chest_sprite=Sprite2D.new(); chest_sprite.texture=CHEST; chest_sprite.scale=Vector2(1.3,1.3); chest_sprite.global_position=Vector2(640,350); add_child(chest_sprite); objective_label.text="صندوق باز شد؛ به مرکز نقشه برو"

func _open_chest() -> void:
    if not chest_active: return
    chest_active=false; chest_sprite.texture=CHEST_OPEN; AudioManager.play_click()
    var reward_info:=GameState.complete_stage(current_stage,stage_score,int(level.reward)); _show_victory(reward_info)

func _spawn_enemy(as_boss: bool) -> void:
    var e=EnemyScene.instantiate(); var kinds=["drone","stalker","brute","warden"]; var kind="core_titan" if as_boss else kinds[(spawned+current_stage)%kinds.size()]
    var elite:=not as_boss and randf() < float(level.elite_rate); e.setup(kind,float(level.difficulty),elite,as_boss)
    if as_boss: e.add_to_group("stage_boss")
    var edge:=randi()%4
    match edge:
        0: e.global_position=Vector2(randf_range(80,1200),90)
        1: e.global_position=Vector2(randf_range(80,1200),630)
        2: e.global_position=Vector2(70,randf_range(120,600))
        _: e.global_position=Vector2(1210,randf_range(120,600))
    add_child(e)

func _update_objective() -> void:
    if objective_label: objective_label.text="پرچم %d / %d — نزدیک پرچم بمان" % [flags_done+1,int(level.flags)]

func _show_victory(info: Dictionary) -> void:
    state = "victory"
    if player:
        player.can_control = false
    var panel:=Control.new(); panel.position=Vector2(390,175); panel.size=Vector2(500,350); ui.add_child(panel)
    var title:=_label("مأموریت کامل",40); title.size=Vector2(480,60); panel.add_child(title)
    var txt:=_label("صندوق %s\n+%d شارد\nامتیاز: %d" % [level.reward_tier,info.shards,stage_score],23); txt.position=Vector2(0,75); txt.size=Vector2(480,110); panel.add_child(txt)
    if not info.unlocked.is_empty(): txt.text += "\nباز شد: " + "، ".join(info.unlocked)
    var next:=_texture_button("مرحله بعد",Vector2(280,65)); next.position=Vector2(200,235); panel.add_child(next); next.get_node("Button").pressed.connect(func(): _start_stage(min(current_stage+1,300)))
    var menu:=_texture_button("منو",Vector2(170,60)); menu.position=Vector2(0,240); panel.add_child(menu); menu.get_node("Button").pressed.connect(_build_menu)

func _on_defeat() -> void:
    state="defeat"; var panel:=Control.new(); panel.position=Vector2(430,220); panel.size=Vector2(420,250); ui.add_child(panel)
    var title:=_label("ماموریت شکست خورد",34); title.size=Vector2(410,60); panel.add_child(title)
    var retry:=_texture_button("تلاش دوباره",Vector2(300,65)); retry.position=Vector2(110,100); panel.add_child(retry); retry.get_node("Button").pressed.connect(func(): _start_stage(current_stage))
    var menu:=_texture_button("منو",Vector2(180,55)); menu.position=Vector2(110,180); panel.add_child(menu); menu.get_node("Button").pressed.connect(_build_menu)

func _clear_game() -> void:
    for n in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(n): n.queue_free()
    if is_instance_valid(player): player.queue_free()
    player=null
    if flag_sprite and is_instance_valid(flag_sprite): flag_sprite.queue_free()
    if chest_sprite and is_instance_valid(chest_sprite): chest_sprite.queue_free()
    flag_sprite=null; chest_sprite=null
