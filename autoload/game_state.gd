extends Node

const SAVE_PATH := "user://drayven_save.json"

var selected_character := "Vex"
var unlocked_characters := ["Vex"]
var unlocked_weapons := ["Pulse Pistol", "Arc SMG"]
var shards := 0
var best_score := 0
var story_chapter := 1
var settings := {"music": 0.75, "sfx": 0.85, "screen_shake": true}

const CHARACTERS := {
    "Vex": {"color": Color("58e6ff"), "accent": Color("aaf7ff"), "hp": 100.0, "speed": 300.0, "ability": "Phase Dash", "desc": "A recon runner who tears through bullets with a phase dash."},
    "Iris": {"color": Color("c972ff"), "accent": Color("f1ceff"), "hp": 125.0, "speed": 255.0, "ability": "Aegis Pulse", "desc": "A tactical engineer who converts danger into a temporary shield."},
    "Brakk": {"color": Color("ff7b4a"), "accent": Color("ffd0bd"), "hp": 165.0, "speed": 220.0, "ability": "Overdrive", "desc": "A heavy breach specialist who enters a brutal fire-rate overdrive."},
    "Nyx": {"color": Color("8d7cff"), "accent": Color("d9d4ff"), "hp": 90.0, "speed": 330.0, "ability": "Void Blink", "desc": "A rogue anomaly who blinks through space and detonates a void wake."}
}

const WEAPONS := {
    "Pulse Pistol": {"damage": 24.0, "fire_rate": 3.4, "speed": 900.0, "spread": 0.01, "pellets": 1, "mag": 12, "reload": 1.0, "color": Color("63e8ff"), "recoil": 3.0},
    "Arc SMG": {"damage": 10.0, "fire_rate": 11.0, "speed": 850.0, "spread": 0.11, "pellets": 1, "mag": 32, "reload": 1.25, "color": Color("7ef5bb"), "recoil": 1.8},
    "Scattergun": {"damage": 11.0, "fire_rate": 1.15, "speed": 720.0, "spread": 0.34, "pellets": 7, "mag": 7, "reload": 1.7, "color": Color("ffb85c"), "recoil": 8.0},
    "Rail Rifle": {"damage": 78.0, "fire_rate": 0.75, "speed": 1450.0, "spread": 0.002, "pellets": 1, "mag": 5, "reload": 2.0, "color": Color("ef7dff"), "recoil": 11.0},
    "Nova Launcher": {"damage": 48.0, "fire_rate": 0.7, "speed": 520.0, "spread": 0.025, "pellets": 1, "mag": 4, "reload": 2.4, "color": Color("ff5f77"), "recoil": 14.0}
}

func _ready() -> void:
    load_save()

func add_shards(amount: int) -> void:
    shards += amount
    save()

func unlock_weapon(name: String) -> void:
    if name not in unlocked_weapons:
        unlocked_weapons.append(name)
        save()

func unlock_character(name: String) -> void:
    if name not in unlocked_characters:
        unlocked_characters.append(name)
        save()

func save() -> void:
    var data := {
        "selected_character": selected_character,
        "unlocked_characters": unlocked_characters,
        "unlocked_weapons": unlocked_weapons,
        "shards": shards,
        "best_score": best_score,
        "story_chapter": story_chapter,
        "settings": settings
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var data = JSON.parse_string(file.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        return
    selected_character = data.get("selected_character", selected_character)
    unlocked_characters = data.get("unlocked_characters", unlocked_characters)
    unlocked_weapons = data.get("unlocked_weapons", unlocked_weapons)
    shards = int(data.get("shards", shards))
    best_score = int(data.get("best_score", best_score))
    story_chapter = int(data.get("story_chapter", story_chapter))
    settings = data.get("settings", settings)
