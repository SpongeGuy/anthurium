extends Resource
class_name Esoterica

## things are as they should be
@export var felicity: float
## divine anger triggered by violation
@export var furor: float
## the ache of absence
@export var lacuna: float
## awe inspired by scale and power
@export var tremendum: float
## spiritual festering
@export var acedia: float
## an inevitable recalling to memory
@export var anamnesis: float

func _init(fe: float = 0.0, fu: float = 0.0, la: float = 0.0, tr: float = 0.0, ac: float = 0.0, an: float = 0.0) -> void:
	felicity = fe
	furor = fu
	lacuna = la
	tremendum = tr
	acedia = ac
	anamnesis = an

func to_array() -> Array[float]:
	return [felicity, furor, lacuna, tremendum, acedia, anamnesis]
	
func get_string() -> String:
	return "fe:%d fu:%d la:%d tr:%d ac:%d an:%d" % [felicity, furor, lacuna, tremendum, acedia, anamnesis]
	
func magnitude() -> float:
	return sqrt(felicity**2 + furor**2 + lacuna**2 + tremendum**2 + acedia**2 + anamnesis**2)
	
func normalized() -> Esoterica:
	var m: float = magnitude()
	if m == 0: return Esoterica.new()
	return Esoterica.new(felicity/m, furor/m, lacuna/m, tremendum/m, acedia/m, anamnesis/m)
	
func dot(other: Esoterica) -> float:
	return felicity*other.felicity + furor*other.furor + lacuna*other.lacuna + tremendum*other.tremendum + acedia*other.acedia + anamnesis*other.anamnesis

## used in multiple ways; [Entity] types have [member Entity.archetype], selecting [BloomEvent]s from [AnthuriumInterface].
func cosine_similarity(other: Esoterica) -> float:
	var denom: float = magnitude() * other.magnitude()
	if denom == 0: return 0
	return dot(other) / denom
	
func add(other: Esoterica) -> void:
	felicity += other.felicity
	furor += other.furor
	lacuna += other.lacuna
	tremendum += other.tremendum
	acedia += other.acedia
	anamnesis += other.anamnesis
