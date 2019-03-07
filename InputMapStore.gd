#Copyright 2019 EmeraldBlade
#Permission is hereby granted, free of charge, to any person obtaining a copy of this 
#software and associated documentation files (the "Software"), to deal in the Software 
#without restriction, including without limitation the rights to use, copy, modify, merge, 
#publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
#to whom the Software is furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all copies or 
#substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
#DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

extends Node
var ignore_list : Array = []

#prevent an action from being saved
func ignore(action : String) -> void:
	if !ignore_list.has(action):
		ignore_list.push_back(action)

#prevent multiple actions from being saved
func ignoreSet(actions : Array) -> void:
	for action in actions:
		ignore(action)

#allow an action to be saved again
func allow(action : String) -> void:
	if ignore_list.has(action):
		ignore_list.erase(action)
		
#allow multiple actions to be saved again
func allowSet(actions : Array) -> void:
	for action in actions:
		allow(action)
	
#just calls InputMap.load_from_globals	
func reset():
	InputMap.load_from_globals()
	
#store the inputmap to a file, ignoring specified actions
#returns the dictionary that is saved as json
#use an empty filename to just get the dictionary
func save(fileName : String) -> Dictionary:
	var map = {}
	var actions = InputMap.get_actions()
	for action in actions:
		#var x = 
		if !ignore_list.has(action):
			var events = InputMap.get_action_list(action)
			var serialized_events = []
			for event in events:
				serialized_events.push_back(serialize_event(event))
			map[action] = serialized_events
	
	if fileName == null || fileName == "":
		return map
	
	var file = File.new()
	file.open(fileName, File.WRITE)
	file.store_string(to_json(map))
	file.close()
	return map

#import a keymap from a file
func import(fileName):
	var file = File.new()
	if !file.file_exists(fileName):
		return
	file.open(fileName, File.READ)
	var map = parse_json(file.get_as_text())
	file.close()
	
	for action in map.keys():
		if !ignore_list.has(action):
			if !InputMap.has_action(action):
				InputMap.add_action(action)
			var s_events = map[action]
			for s_event in s_events:
				var event = deserialize_event(s_event)
				InputMap.action_add_event(action, event)
					

#serialize an event
func serialize_event(event):
	match event.get_class():
		"InputEventAction":
			return {
				type = "action",
				device = event.device,
				index = event.action
			}
		"InputEventJoypadButton":
			return {
				type = "joypadbutton",
				device = event.device,
				index = event.button_index
			}
		"InputEventKey":
			return {
				type = "key",
				device = event.device,
				index = event.scancode,
				modifiers = modifier_mask(event)
			}
		"InputEventMouseButton":
			return {
				type = "mouse",
				device = event.device,
				button_mask = event.button_mask,
				index = event.button_index,
				modifiers = modifier_mask(event)
			}

#deserialize an event
func deserialize_event(map):
	match map["type"]:
		"key":
			var event = InputEventKey.new()
			event.device = int(map["device"])
			event.scancode = int(map["index"])
			inverse_modifier_mask(event, map["modifiers"])
			return event
		"mouse":
			var event = InputEventMouseButton.new()
			event.device = int(map["device"])
			event.button_index = int(map["index"])
			event.button_mask = int(map["button_mask"])
			inverse_modifier_mask(event, map["modifiers"])
			return event
		"joypadbutton":
			var event = InputEventJoypadButton.new()
			event.device = int(map["device"])
			event.button_index = int(map["index"])
			return event
		"action":
			var event = InputEventAction.new()
			event.device = int(map["device"])
			event.action = int(map["index"])
			return event

#create a bitmask to store modifier keys
func modifier_mask(event):
	var r = 0
	if event is InputEventWithModifiers:
		if event.alt: r += 1
		if event.control: r+= 2
		if event.command: r+= 4
		if event.meta: r+= 8
		if event.shift: r+= 16

	return r

#revert bitmask for modifier keys
func inverse_modifier_mask(event, mask):
	mask = int(mask)
	if event is InputEventWithModifiers:
		event.alt = mask & 1 == 1
		event.control = mask & 2 == 2
		event.command = mask & 4 == 4
		event.meta = mask &  8 == 8
		event.shift = mask & 16 == 16














