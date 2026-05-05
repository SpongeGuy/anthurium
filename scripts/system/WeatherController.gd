extends Node
class_name WeatherController

# -----------------------------------------------------------
# fog interface
# -----------------------------------------------------------

@export var disabled: bool = false

var weather: WeatherComponent
static var target: Node2D

var default_pulse_params: Dictionary = {
	TimeManager.DayState.DAWN: [100, 125, 1],
	TimeManager.DayState.DAY: [1000, 1250, 1],
	TimeManager.DayState.DUSK: [100, 125, 1],
	TimeManager.DayState.NIGHT: [1, 5, 1],
}

func _ready() -> void:
	EventBus.weather_ready.connect(_on_weather_ready)
	EventBus.change_fog_pulse_params.connect(set_fog_pulse_params)
	EventBus.day_state_changed.connect(_on_day_state_changed)
	
func _physics_process(delta: float) -> void:
	if not target:
		return
	if disabled:
		change_fog_radius_to(10000, delta)
		return
	move_fog_to(target.global_position, delta)
	fog_pulse(delta)
	
	
	
func _on_day_state_changed(state: TimeManager.DayState, name: String) -> void:
	var minim: float = default_pulse_params[state][0]
	var maxim: float = default_pulse_params[state][1]
	var rate: float = default_pulse_params[state][2]
	set_fog_pulse_params(minim, maxim, rate)
	
func _on_weather_ready(w: WeatherComponent) -> void:
	weather = w

static func change_fog_target(new_target: Node2D) -> void:
	target = new_target
	EventBus.fog_target_changed.emit(target)




func move_fog_instantly_to(pos: Vector2) -> void:
	weather.fog_position = pos
	weather.fog_area.global_position = pos
	weather.fog_shape.material.set_shader_parameter("center_pos", weather.fog_position)
	
	
func move_fog_to(pos: Vector2, delta: float) -> void:
	weather.fog_position = lerp(weather.fog_position, pos, delta)
	weather.fog_area.global_position = lerp(weather.fog_area.global_position, pos, delta)
	weather.fog_shape.material.set_shader_parameter("center_pos", weather.fog_position)
	

func change_fog_radius_to(radius: float, delta) -> void:
	weather.fog_radius = lerp(weather.fog_radius, radius, delta)
	weather.fog_collision_shape.shape.radius = lerp(weather.fog_collision_shape.shape.radius, radius * 0.6, delta)
	weather.fog_shape.material.set_shader_parameter("clear_radius", weather.fog_radius)

	
var fog_pulse_maximum_radius: float = 100
var fog_pulse_minimum_radius: float = 20
var fog_pulse_frequency: float = 2

func set_fog_pulse_params(minimum: float, maximum: float, frequency: float) -> void:
	fog_pulse_maximum_radius = maximum
	fog_pulse_minimum_radius = minimum
	fog_pulse_frequency = frequency

func fog_pulse(delta: float) -> void:
	var f_radius: float = abs((fog_pulse_maximum_radius - fog_pulse_minimum_radius) * sin(fog_pulse_frequency * TimeManager.elapsed) + fog_pulse_maximum_radius + fog_pulse_minimum_radius)
	change_fog_radius_to(f_radius, delta)

func change_weather_tint_to(delta: float, color: Color) -> void:
	weather.weather_tint.color = lerp(weather.weather_tint.color, color, delta)

func change_fog_color_to(delta: float, color: Color) -> void:
	weather.fog_color = lerp(weather.fog_color, color, delta)
	weather.fog_shape.material.set_shader_parameter("fog_color", weather.fog_color)
