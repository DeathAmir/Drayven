extends Area2D

var direction := Vector2.RIGHT
var speed := 900.0
var damage := 20.0
var tint := Color.CYAN
var life := 1.7
var explosive := false
var owner_player = null

func _ready() -> void:
    var shape := CircleShape2D.new()
    shape.radius = 5.0 if not explosive else 8.0
    var collider := CollisionShape2D.new()
    collider.shape = shape
    add_child(collider)
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    life -= delta
    if life <= 0.0:
        queue_free()
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 6.0 if not explosive else 10.0, tint)
    draw_line(-direction * 18.0, Vector2.ZERO, Color(tint.r, tint.g, tint.b, 0.32), 4.0)

func _on_body_entered(body: Node) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage, global_position)
        if owner_player and owner_player.has_method("register_hit"):
            owner_player.register_hit(damage)
        if explosive:
            for target in get_tree().get_nodes_in_group("enemies"):
                if is_instance_valid(target) and target != body and target.global_position.distance_to(global_position) < 90.0:
                    target.take_damage(damage * 0.55, global_position)
        queue_free()
