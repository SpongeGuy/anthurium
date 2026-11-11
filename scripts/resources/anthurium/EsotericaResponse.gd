extends Resource
class_name EsotericaResponse

# override this!
func get_delta(context: Dictionary) -> Esoterica:
	return Esoterica.new()
