-- global event manager which can send and receive data from other sources

EventManager = {
	listeners = {}
}

function EventManager:subscribe(event_type, callback)
	if not self.listeners[event_type] then
		self.listeners[event_type] = {}
	end
	table.insert(self.listeners[event_type], callback)
end

function EventManager:broadcast(event_type, data)
	if self.listeners[event_type] then
		for _, callback in ipairs(self.listeners[event_type]) do
			callback(data)
		end
	end
end