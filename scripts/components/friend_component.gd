extends Component
class_name FriendComponent

var friend_list: Array[Node2D]

func add_friend(friend: Node2D) -> void:
	if friend in friend_list:
		return
	friend_list.append(friend)
	
func remove_friend(friend: Node2D) -> void:
	if friend in friend_list:
		friend_list.erase(friend)
		
func is_friend(friend: Node2D) -> bool:
	if not is_instance_valid(friend):
		return false
	if friend in friend_list:
		return true
	return false
