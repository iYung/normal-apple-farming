-- test_settings_state.lua
local SettingsState = require("game/settings_state")

-- 1: default constructor
local s = SettingsState.new()
assert(s.fullscreen == false, "default fullscreen should be false")
assert(s.keybinds.move_up    == "w",     "default move_up")
assert(s.keybinds.move_down  == "s",     "default move_down")
assert(s.keybinds.move_left  == "a",     "default move_left")
assert(s.keybinds.move_right == "d",     "default move_right")
assert(s.keybinds.interact   == "e",     "default interact")
print("PASS: default constructor")

-- 2: toggle_fullscreen flips the flag
local s2 = SettingsState.new()
s2:toggle_fullscreen()
assert(s2.fullscreen == true, "fullscreen should be true after toggle")
s2:toggle_fullscreen()
assert(s2.fullscreen == false, "fullscreen should be false after second toggle")
print("PASS: toggle_fullscreen")

-- 3: set_keybind assigns a key
local s3 = SettingsState.new()
s3:set_keybind("move_up", "i")
assert(s3.keybinds.move_up == "i", "move_up should be i")
print("PASS: set_keybind assigns key")

-- 4: set_keybind is a simple assignment, no conflict clearing
local s4 = SettingsState.new()
-- "s" is currently bound to move_down; bind move_up to "s" instead
s4:set_keybind("move_up", "s")
assert(s4.keybinds.move_up   == "s",  "move_up should now be s")
assert(s4.keybinds.move_down == "s",  "move_down should still be s (conflict not cleared)")
print("PASS: set_keybind is a simple assignment, no conflict clearing")

-- 5: key_map returns correct Input format
local s5 = SettingsState.new()
local m = s5:key_map()
assert(type(m.move_up) == "table",   "key_map move_up should be a table")
assert(m.move_up[1]    == "w",       "key_map move_up[1] should be w")
assert(m.interact[1]   == "e",       "key_map interact[1] should be e")
print("PASS: key_map format")

-- 6: key_map omits nil bindings
local s6 = SettingsState.new()
s6.keybinds.move_up = nil
local m6 = s6:key_map()
assert(m6.move_up == nil, "nil binding should not appear in key_map")
print("PASS: key_map omits nil bindings")

-- 7: to_save / from_save round-trip
local s7 = SettingsState.new()
s7:toggle_fullscreen()
s7:set_keybind("move_up", "i")
local saved = s7:to_save()
assert(saved.fullscreen      == true, "saved fullscreen should be true")
assert(saved.keybinds.move_up == "i", "saved move_up should be i")

local s7b = SettingsState.from_save(saved)
assert(s7b.fullscreen          == true, "restored fullscreen")
assert(s7b.keybinds.move_up    == "i",  "restored move_up")
assert(s7b.keybinds.move_down  == "s",  "restored move_down default")
print("PASS: to_save / from_save round-trip")

-- 8: from_save with nil returns defaults
local s8 = SettingsState.from_save(nil)
assert(s8.fullscreen         == false, "nil save: default fullscreen")
assert(s8.keybinds.move_up   == "w",   "nil save: default move_up")
print("PASS: from_save nil returns defaults")

-- 9: from_save ignores unknown keybind actions
local s9 = SettingsState.from_save({ keybinds = { move_up = "i", unknown_action = "x" } })
assert(s9.keybinds.move_up        == "i",  "known action loaded")
assert(s9.keybinds.unknown_action == nil,  "unknown action ignored")
print("PASS: from_save ignores unknown actions")

print("ALL TESTS PASSED")
