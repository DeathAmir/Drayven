extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, maximum: int, weapon: String)
signal died
signal score_changed(score: int)
signal ability_changed(value: float, maximum: float)

const BulletScene := preload("res://scenes/Bullet.tscn")
const PLAYER_TEXTURE := preload("res://assets/vendor/characters/topdown_man.png")

var character_name := "Vex"
var hp := 100.0
var max_hp := 100.0
var move_speed := 300.0
var weapon_name := "Pulse Pistol"
var ammo := 14
var fire_cd := 0.0
var reload_timer := 0.0
var ability_cd := 0.0
var ability_max := 4.0
var invulnerable := 0.0
var overdrive := 0.0
var shield := 0.0
var score := 0
var can_control := true
var aim_dir := Vector2.UP
var mobile_move := Vector2.ZERO
var move_touch_id := -1
var aim_touch_id := -1
var move_touch_origin := Vector2.ZERO
var mobile_firing := false
var sprite: Sprite2D
var anim_clock := 0.0

func _ready() -> void:
    add_to_group("player")
    var shape := CircleShape2D.new()
    shape.radius = 22.0
    $CollisionShape2D.shape = shape
    sprite = Sprite2D.new()
    sprite.texture = PLAYER_TEXTURE
    sprite.hframes = 7
    sprite.frame = 0
    sprite.scale = Vector2(0.43, 0.43)
    add_child(sprite)
    setup(GameState.selected_character)

func setup(name: String) -> void:
    character_name = name if GameState.CHARACTERS.has(name) else "Vex"
    var d: Dictionary = GameState.CHARACTERS[character_name]
    max_hp = float(d.hp)
    hp = max_hp
    move_speed = float(d.speed)
    weapon_name = str(GameState.unlocked_weapons[0]) if not GameState.unlocked_weapons.is_empty() else "Pulse Pistol"
    ammo = int(GameState.WEAPONS[weapon_name].mag)
    health_changed.emit(hp, max_hp)
    _emit_ammo()

func _physics_process(delta: float) -> void:
    fire_cd = maxf(0.0, fire_cd - delta)
    ability_cd = maxf(0.0, ability_cd - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    overdrive = maxf(0.0, overdrive - delta)
    shield = maxf(0.0, shield - delta)
    ability_changed.emit(ability_max - ability_cd, ability_max)
    if reload_timer > 0.0:
        reload_timer -= delta
        if reload_timer <= 0.0:
            ammo = int(GameState.WEAPONS[weapon_name].mag)
            _emit_ammo()
    if not can_control:
        velocity = Vector2.ZERO
        return
    var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if mobile_move.length() > 0.03:
        move = mobile_move
    velocity = move * move_speed * (1.22 if overdrive > 0.0 else 1.0)
    move_and_slide()
    global_position.x = clampf(global_position.x, 45.0, 1235.0)
    global_position.y = clampf(global_position.y, 75.0, 660.0)
    if move.length() > 0.08:
        anim_clock += delta * 9.5
        sprite.frame = int(anim_clock) % 7
    else:
        sprite.frame = 0
    rotation = aim_dir.angle() + PI / 2.0
    sprite.modulate = Color(0.65,0.9,1.0) if shield > 0.0 else Color.WHITE
    if mobile_firing or Input.is_action_pressed("shoot"):
        shoot()
    if Input.is_action_just_pressed("ability"): use_ability()
    if Input.is_action_just_pressed("reload"): reload()
    if Input.is_action_just_pressed("next_weapon"): cycle_weapon(1)
    if not mobile_firing and aim_touch_id == -1:
        var mouse_dir := global_position.direction_to(get_global_mouse_position())
        if mouse_dir.length() > 0.2: aim_dir = mouse_dir

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport_rect().size.x * 0.47 and move_touch_id == -1:
                move_touch_id = event.index
                move_touch_origin = event.position
            elif aim_touch_id == -1:
                aim_touch_id = event.index
                aim_dir = global_position.direction_to(event.position)
                mobile_firing = true
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                mobile_move = Vector2.ZERO
            if event.index == aim_touch_id:
                aim_touch_id = -1
                mobile_firing = false
    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            mobile_move = (event.position - move_touch_origin).limit_length(95.0) / 95.0
        elif event.index == aim_touch_id:
            var d := global_position.direction_to(event.position)
            if d.length() > 0.05: aim_dir = d

func set_touch_move(v: Vector2) -> void:
    mobile_move = v.limit_length(1.0)

func set_touch_fire(active: bool) -> void:
    mobile_firing = active

func set_touch_aim(v: Vector2) -> void:
    if v.length() > 0.05: aim_dir = v.normalized()

func shoot() -> void:
    if fire_cd > 0.0 or reload_timer > 0.0:
        return
    if ammo <= 0:
        reload(); return
    var w: Dictionary = GameState.WEAPONS[weapon_name]
    ammo -= 1
    fire_cd = 1.0 / (float(w.fire_rate) * (1.75 if overdrive > 0.0 else 1.0))
    _emit_ammo()
    AudioManager.play_shot()
    for _pellet in range(int(w.pellets)):
        var bullet = BulletScene.instantiate()
        bullet.global_position = global_position + aim_dir * 30.0
        bullet.direction = aim_dir.rotated(randf_range(-float(w.spread), float(w.spread)))
        bullet.speed = float(w.speed)
        bullet.damage = float(w.damage) * (1.18 if overdrive > 0.0 else 1.0)
        bullet.explosive = weapon_name == "Nova Launcher"
        bullet.owner_player = self
        get_parent().add_child(bullet)

func reload() -> void:
    if reload_timer > 0.0: return
    var w: Dictionary = GameState.WEAPONS[weapon_name]
    if ammo >= int(w.mag): return
    reload_timer = float(w.reload)

func cycle_weapon(dir: int) -> void:
    if GameState.unlocked_weapons.is_empty(): return
    var idx := GameState.unlocked_weapons.find(weapon_name)
    idx = posmod(idx + dir, GameState.unlocked_weapons.size())
    weapon_name = str(GameState.unlocked_weapons[idx])
    ammo = int(GameState.WEAPONS[weapon_name].mag)
    reload_timer = 0.0
    _emit_ammo()

func use_ability() -> void:
    if ability_cd > 0.0: return
    match character_name:
        "Vex":
            ability_max = 3.8; invulnerable = 0.35
            global_position += aim_dir * 170.0
        "Iris":
            ability_max = 7.0; shield = 3.5
        "Brakk":
            ability_max = 8.0; overdrive = 4.0
        "Nyx":
            ability_max = 5.0; invulnerable = 0.45
            global_position += aim_dir * 230.0
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if enemy.global_position.distance_to(global_position) < 125.0:
                    enemy.take_damage(42.0, global_position)
    global_position.x = clampf(global_position.x, 45.0, 1235.0)
    global_position.y = clampf(global_position.y, 75.0, 660.0)
    ability_cd = ability_max

func take_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    if invulnerable > 0.0: return
    if shield > 0.0: amount *= 0.3
    hp -= amount
    invulnerable = 0.13
    if source != Vector2.ZERO: velocity += source.direction_to(global_position) * 90.0
    health_changed.emit(maxf(hp, 0.0), max_hp)
    if hp <= 0.0:
        can_control = false
        died.emit()

func heal(amount: float) -> void:
    hp = minf(max_hp, hp + amount)
    health_changed.emit(hp, max_hp)

func register_hit(_amount: float) -> void:
    pass

func register_kill(points: int) -> void:
    score += points
    score_changed.emit(score)

func _emit_ammo() -> void:
    ammo_changed.emit(ammo, int(GameState.WEAPONS[weapon_name].mag), weapon_name)
