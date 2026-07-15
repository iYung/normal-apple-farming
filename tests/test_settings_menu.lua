-- test_settings_menu.lua
-- Verifies SettingsMenu:_confirm() item-4 ("Exit to Title") behavior:
-- it must invoke the on_exit_to_title callback instead of quitting directly,
-- and must never error when on_exit_to_title is omitted.

local SettingsState = require("game/settings_state")
local SettingsMenu  = require("game/scenes/settings_menu")

-- ── item 4 calls on_exit_to_title, not love.event.quit, and closes the menu ──

do
    local exit_calls = 0
    local menu = SettingsMenu.new(
        SettingsState.new(),
        nil,
        function() end,
        function() exit_calls = exit_calls + 1 end
    )

    local quit_calls = 0
    local orig_quit = love.event.quit
    love.event.quit = function(...) quit_calls = quit_calls + 1 end

    menu.is_open = true
    menu.selected = 4
    menu:_confirm()

    love.event.quit = orig_quit

    assert(exit_calls == 1, "on_exit_to_title should be called exactly once")
    assert(quit_calls == 0, "love.event.quit should not be called directly by item 4")
    assert(menu.is_open == false, "is_open should be false after exiting to title")
    print("PASS: SettingsMenu item 4 calls on_exit_to_title and closes menu")
end

-- ── item 4 with on_exit_to_title == nil does not error ───────────────────────

do
    local menu = SettingsMenu.new(
        SettingsState.new(),
        nil,
        function() end
        -- on_exit_to_title omitted (nil)
    )

    menu.is_open = true
    menu.selected = 4

    local ok, err = pcall(function() menu:_confirm() end)
    assert(ok, "menu:_confirm() should not error when on_exit_to_title is nil: " .. tostring(err))
    print("PASS: SettingsMenu item 4 with nil on_exit_to_title does not error")
end

print("ALL TESTS PASSED")
