extends Node

const SAVE_PATH := "user://drayven_save_v2.json"
const SAVE_PEPPER := "DRAYVEN-MOBILE-2026-CTF-v2"

var selected_character := "Vex"
var unlocked_characters: Array = ["Vex"]
var unlocked_weapons: Array = ["Pulse Pistol", "Arc SMG"]
var shards := 0
var best_score := 0
var highest_stage := 1
var selected_stage := 1
var completed_stages: Array = []
var stage_best: Dictionary = {}
var save_tampered := false
var settings := {"music": 0.72, "sfx": 0.9, "shake": true}

const CHARACTERS := {
    "Vex": {"hp":100.0, "speed":315.0, "ability":"Phase Dash", "fa":"وکس — جهش فازی"},
    "Iris": {"hp":125.0, "speed":270.0, "ability":"Aegis Pulse", "fa":"آیریس — سپر پالسی"},
    "Brakk": {"hp":165.0, "speed":235.0, "ability":"Overdrive", "fa":"براک — اوردرایو"},
    "Nyx": {"hp":92.0, "speed":340.0, "ability":"Void Blink", "fa":"نیکس — پرش خلأ"}
}

const WEAPONS := {
    "Pulse Pistol": {"damage":24.0,"fire_rate":3.5,"speed":950.0,"spread":0.015,"pellets":1,"mag":14,"reload":0.9,"recoil":2.0,"fa":"تپانچه پالسی"},
    "Arc SMG": {"damage":10.5,"fire_rate":11.5,"speed":880.0,"spread":0.10,"pellets":1,"mag":34,"reload":1.2,"recoil":1.4,"fa":"مسلسل آرک"},
    "Scattergun": {"damage":11.5,"fire_rate":1.15,"speed":760.0,"spread":0.34,"pellets":7,"mag":7,"reload":1.65,"recoil":7.0,"fa":"شاتگان پراکنده"},
    "Rail Rifle": {"damage":82.0,"fire_rate":0.78,"speed":1500.0,"spread":0.003,"pellets":1,"mag":5,"reload":1.9,"recoil":10.0,"fa":"رایفل ریلی"},
    "Nova Launcher": {"damage":52.0,"fire_rate":0.72,"speed":560.0,"spread":0.02,"pellets":1,"mag":4,"reload":2.25,"recoil":13.0,"fa":"پرتابگر نُوا"}
}

func _ready() -> void:
    load_save()

func _signature(payload: String) -> String:
    var h := HashingContext.new()
    h.start(HashingContext.HASH_SHA256)
    h.update((SAVE_PEPPER + payload).to_utf8_buffer())
    return h.finish().hex_encode()

func save() -> void:
    var data := {
        "selected_character": selected_character,
        "unlocked_characters": unlocked_characters,
        "unlocked_weapons": unlocked_weapons,
        "shards": shards,
        "best_score": best_score,
        "highest_stage": highest_stage,
        "selected_stage": selected_stage,
        "completed_stages": completed_stages,
        "stage_best": stage_best,
        "settings": settings
    }
    var payload := JSON.stringify(data)
    var wrapper := {"payload": payload, "sha256": _signature(payload), "version": 2}
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(wrapper))

func load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f:
        return
    var wrapper = JSON.parse_string(f.get_as_text())
    if typeof(wrapper) != TYPE_DICTIONARY:
        save_tampered = true
        return
    var payload := str(wrapper.get("payload", ""))
    if payload.is_empty() or str(wrapper.get("sha256", "")) != _signature(payload):
        save_tampered = true
        return
    var data = JSON.parse_string(payload)
    if typeof(data) != TYPE_DICTIONARY:
        save_tampered = true
        return
    selected_character = str(data.get("selected_character", selected_character))
    if not CHARACTERS.has(selected_character): selected_character = "Vex"
    unlocked_characters = data.get("unlocked_characters", unlocked_characters)
    unlocked_weapons = data.get("unlocked_weapons", unlocked_weapons)
    shards = clampi(int(data.get("shards", 0)), 0, 99999999)
    best_score = clampi(int(data.get("best_score", 0)), 0, 999999999)
    highest_stage = clampi(int(data.get("highest_stage", 1)), 1, 300)
    selected_stage = clampi(int(data.get("selected_stage", highest_stage)), 1, highest_stage)
    completed_stages = data.get("completed_stages", [])
    stage_best = data.get("stage_best", {})
    settings = data.get("settings", settings)

func add_shards(amount: int) -> void:
    shards = clampi(shards + max(amount, 0), 0, 99999999)
    save()

func complete_stage(stage_id: int, score: int, reward: int) -> Dictionary:
    stage_id = clampi(stage_id, 1, 300)
    if stage_id not in completed_stages:
        completed_stages.append(stage_id)
    highest_stage = max(highest_stage, min(stage_id + 1, 300))
    selected_stage = highest_stage
    shards = clampi(shards + reward, 0, 99999999)
    best_score = max(best_score, score)
    var key := str(stage_id)
    stage_best[key] = max(int(stage_best.get(key, 0)), score)
    var unlocked: Array[String] = []
    if stage_id >= 15 and "Scattergun" not in unlocked_weapons:
        unlocked_weapons.append("Scattergun"); unlocked.append("Scattergun")
    if stage_id >= 35 and "Iris" not in unlocked_characters:
        unlocked_characters.append("Iris"); unlocked.append("Iris")
    if stage_id >= 60 and "Rail Rifle" not in unlocked_weapons:
        unlocked_weapons.append("Rail Rifle"); unlocked.append("Rail Rifle")
    if stage_id >= 100 and "Brakk" not in unlocked_characters:
        unlocked_characters.append("Brakk"); unlocked.append("Brakk")
    if stage_id >= 150 and "Nova Launcher" not in unlocked_weapons:
        unlocked_weapons.append("Nova Launcher"); unlocked.append("Nova Launcher")
    if stage_id >= 220 and "Nyx" not in unlocked_characters:
        unlocked_characters.append("Nyx"); unlocked.append("Nyx")
    save()
    return {"unlocked": unlocked, "shards": reward}
