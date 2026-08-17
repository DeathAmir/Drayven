extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, maximum: int, weapon: String)
signal died
signal score_changed(score: int)
signal ability_changed(value: float, maximum: float)
signal weapon_changed(name: String)

var character_name := "Vex"
var hp := 100.0
var max_hp := 100.0
var move_speed := 300.0
var weapon_name := "Pulse Pistol"
var ammo := 12
var fire_cd := 0.0
var reload_timer := 0.0
var ability_cd := 0.0
var ability_max := 5.0
var invulnerable := 0.0
var overdrive := 0.0
var shield := 0.0
var score := 0
var kills := 0
var can_control := true
var mobile_move := Vector2.ZERO
var mobile_aim := Vector2.RIGHT
var move_touch_id := -1
var shoot_touch_id := -1
var move_touch_origin := Vector2.ZERO
var mobile_shoot := false
var BulletScene := preload("res://scenes/Bullet.tscn")

func setup(name: String) -> void:
    character_name = name
    var data: Dictionary = GameState.CHARACTERS[character_name]
    max_hp = float(data.hp)
    hp = max_hp
    move_speed = float(data.speed)
    weapon_name = GameState.unlocked_weapons[0] if not GameState.unlocked_weapons.is_empty() else "Pulse Pistol"
    ammo = int(GameState.WEAPONS[weapon_name].mag)
    queue_redraw()
    health_changed.emit(hp, max_hp)
    _emit_ammo()

func _ready() -> void:
    add_to_group("player")
    var shape := CapsuleShape2D.new()
    shape.radius = 14.0
    shape.height = 38.0
    $CollisionShape2D.shape = shape
    setup(GameState.selected_character)

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
        velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
        move_and_slide()
        return
    var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if mobile_move.length() > 0.05:
        move = mobile_move
    velocity = move * move_speed * (1.22 if overdrive > 0.0 else 1.0)
    move_and_slide()
    global_position.x = clampf(global_position.x, 36.0, 1244.0)
    global_position.y = clampf(global_position.y, 58.0, 684.0)
    if mobile_shoot:
        look_at(global_position + mobile_aim * 500.0)
        shoot()
    elif Input.is_action_pressed("shoot"):
        shoot()
    if Input.is_action_just_pressed("ability"):
        use_ability()
    if Input.is_action_just_pressed("reload"):
        reload()
    if Input.is_action_just_pressed("next_weapon"):
        cycle_weapon(1)
    if Input.is_action_just_pressed("prev_weapon"):
        cycle_weapon(-1)
    if not mobile_shoot:
        look_at(get_global_mouse_position())
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport_rect().size.x * 0.48 and move_touch_id == -1:
                move_touch_id = event.index
                move_touch_origin = event.position
            elif shoot_touch_id == -1:
                shoot_touch_id = event.index
                mobile_aim = global_position.direction_to(event.position)
                mobile_shoot = true
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                mobile_move = Vector2.ZERO
            if event.index == shoot_touch_id:
                shoot_touch_id = -1
                mobile_shoot = false
    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            mobile_move = (event.position - move_touch_origin).limit_length(90.0) / 90.0
        elif event.index == shoot_touch_id:
            mobile_aim = global_position.direction_to(event.position)

func shoot() -> void:
    if fire_cd > 0.0 or reload_timer > 0.0:
        return
    if ammo <= 0:
        reload()
        return
    var w: Dictionary = GameState.WEAPONS[weapon_name]
    ammo -= 1
    var rate: float = float(w.fire_rate) * (1.75 if overdrive > 0.0 else 1.0)
    fire_cd = 1.0 / rate
    _emit_ammo()
    for pellet in range(int(w.pellets)):
        var bullet = BulletScene.instantiate()
        bullet.global_position = global_position + Vector2(27.0, 0.0).rotated(rotation)
        var variance := randf_range(-float(w.spread), float(w.spread))
        bullet.direction = Vector2.RIGHT.rotated(rotation + variance)
        bullet.speed = float(w.speed)
        bullet.damage = float(w.damage) * (1.18 if overdrive > 0.0 else 1.0)
        bullet.tint = w.color
        bullet.explosive = weapon_name == "Nova Launcher"
        bullet.owner_player = self
        get_parent().add_child(bullet)
    velocity -= Vector2.RIGHT.rotated(rotation) * float(w.recoil) * 12.0

func reload() -> void:
    if reload_timer > 0.0:
        return
    var w: Dictionary = GameState.WEAPONS[weapon_name]
    if ammo >= int(w.mag):
        return
    reload_timer = float(w.reload)

func cycle_weapon(dir: int) -> void:
    if GameState.unlocked_weapons.is_empty():
        return
    var idx := GameState.unlocked_weapons.find(weapon_name)
    idx = posmod(idx + dir, GameState.unlocked_weapons.size())
    weapon_name = GameState.unlocked_weapons[idx]
    ammo = int(GameState.WEAPONS[weapon_name].mag)
    reload_timer = 0.0
    weapon_changed.emit(weapon_name)
    _emit_ammo()

func use_ability() -> void:
    if ability_cd > 0.0:
        return
    match character_name:
        "Vex":
            ability_max = 3.8
            invulnerable = 0.32
            global_position += Vector2.RIGHT.rotated(rotation) * 155.0
            global_position.x = clampf(global_position.x, 36.0, 1244.0)
            global_position.y = clampf(global_position.y, 58.0, 684.0)
        "Iris":
            ability_max = 7.0
            shield = 3.5
        "Brakk":
            ability_max = 8.0
            overdrive = 4.0
        "Nyx":
            ability_max = 5.2
            invulnerable = 0.5
            global_position = get_global_mouse_position()
            global_position.x = clampf(global_position.x, 36.0, 1244.0)
            global_position.y = clampf(global_position.y, 58.0, 684.0)
            for enemy in get_tree().get_nodes_in_group("enemies"):
                if enemy.global_position.distance_to(global_position) < 115.0:
                    enemy.take_damage(34.0, global_position)
    ability_cd = ability_max

func take_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    if invulnerable > 0.0:
        return
    if shield > 0.0:
        amount *= 0.28
    hp -= amount
    invulnerable = 0.16
    if source != Vector2.ZERO:
        velocity += source.direction_to(global_position) * 100.0
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
    kills += 1
    score += points
    score_changed.emit(score)

func _emit_ammo() -> void:
    ammo_changed.emit(ammo, int(GameState.WEAPONS[weapon_name].mag), weapon_name)

func _draw() -> void:
    var data: Dictionary = GameState.CHARACTERS.get(character_name, GameState.CHARACTERS["Vex"])
    var c: Color = data.color
    draw_circle(Vector2.ZERO, 18.0, Color("08131d"))
    draw_circle(Vector2.ZERO, 15.0, c)
    draw_circle(Vector2(4, -3), 5.0, Color("e8fbff"))
    draw_line(Vector2(12, 0), Vector2(31, 0), GameState.WEAPONS[weapon_name].color, 7.0, true)
    draw_line(Vector2(-5, 13), Vector2(-12, 24), Color(c.r, c.g, c.b, 0.75), 6.0, true)
    draw_line(Vector2(5, 13), Vector2(12, 24), Color(c.r, c.g, c.b, 0.75), 6.0, true)
    if shield > 0.0:
        draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color("c984ff"), 3.0)
    if invulnerable > 0.0:
        draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, Color(1,1,1,0.55), 2.0)
