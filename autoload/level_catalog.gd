extends Node

const SECTORS := [
    {"name":"منطقه خاموشی", "story":"شبکه شهر در یازده ثانیه فروپاشید. اولین پرچم‌های مقاومت را از دست نگهبان‌های ماشینی پس بگیر."},
    {"name":"بندر شیشه‌ای", "story":"کانتینرهای انرژی به دست گروه صفر افتاده‌اند. مسیر ساحلی را پاکسازی کن و صندوق‌های قاچاق را باز کن."},
    {"name":"متروی غرق‌شده", "story":"سیگنال درایون از تونل‌های مترو می‌آید. پرچم‌ها مسیر امن را فعال می‌کنند."},
    {"name":"کارخانه سرخ", "story":"خط تولید پهپادها هنوز فعال است. هر پرچم یک بخش از کارخانه را از مدار خارج می‌کند."},
    {"name":"برج‌های نئون", "story":"تک‌تیراندازهای خودکار بالای برج‌ها هستند. پرچم‌ها را یکی‌یکی بگیر و زنده بمان."},
    {"name":"کویر آینه‌ها", "story":"دشمن سیگنال‌های جعلی می‌سازد. فقط پرچم‌های واقعی راه صندوق فرماندهی را باز می‌کنند."},
    {"name":"دژ اوربیتال", "story":"سامانه دفاعی شهر از مدار کنترل می‌شود. هر مأموریت یک گره دفاعی را می‌شکند."},
    {"name":"آزمایشگاه صفر", "story":"پرونده‌های پروژه درایون اینجاست. نگهبان‌های نخبه برای هر پرچم فعال می‌شوند."},
    {"name":"شهر زیرین", "story":"بازمانده‌ها زیر شهر پنهان شده‌اند. مسیر تدارکات را با تصرف پرچم‌ها پس بگیر."},
    {"name":"دروازه خلأ", "story":"شکاف‌های فضایی میدان نبرد را ناپایدار کرده‌اند. سرعت و کنترل مهم‌تر از قدرت خام است."},
    {"name":"قلعه تایتان", "story":"فرمانده‌های اصلی درایون اینجا جمع شده‌اند. هر پنج مرحله یک موج نخبه منتظر توست."},
    {"name":"قلب درایون", "story":"بیست‌وپنج مأموریت آخر؛ پرچم‌ها قفل هسته را می‌شکنند و صندوق نهایی حقیقت را آشکار می‌کند."}
]

var levels: Array[Dictionary] = []

func _ready() -> void:
    for stage_id in range(1, 301):
        var sector_index := int((stage_id - 1) / 25)
        var within := ((stage_id - 1) % 25) + 1
        var flags := clampi(1 + int((stage_id - 1) / 75), 1, 4)
        var enemies := clampi(7 + int(stage_id * 0.12), 7, 46)
        var elite_rate := clampf(0.04 + float(stage_id) * 0.0011, 0.04, 0.34)
        var difficulty := 1.0 + float(stage_id - 1) * 0.011
        var reward := 20 + stage_id * 2
        var tier := "عادی"
        if stage_id % 25 == 0:
            tier = "افسانه‌ای"
            reward += 250
        elif stage_id % 10 == 0:
            tier = "حماسی"
            reward += 90
        elif stage_id % 5 == 0:
            tier = "کمیاب"
            reward += 40
        levels.append({
            "id": stage_id,
            "sector": sector_index + 1,
            "sector_name": SECTORS[sector_index].name,
            "story": SECTORS[sector_index].story,
            "mission": within,
            "title": "مرحله %03d — مأموریت %02d" % [stage_id, within],
            "flags": flags,
            "enemy_count": enemies,
            "difficulty": difficulty,
            "elite_rate": elite_rate,
            "boss": stage_id % 25 == 0,
            "reward": reward,
            "reward_tier": tier,
            "spawn_delay": maxf(0.28, 0.82 - float(stage_id) * 0.0016)
        })

func get_level(stage_id: int) -> Dictionary:
    return levels[clampi(stage_id, 1, 300) - 1]
