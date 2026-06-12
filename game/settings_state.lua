local SettingsState = {}
SettingsState.__index = SettingsState

function SettingsState.new()
    local self = setmetatable({}, SettingsState)
    self.fullscreen = false
    self.keybinds = {move_up="w", move_down="s", move_left="a", move_right="d", interact="space"}
    return self
end

function SettingsState:toggle_fullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setFullscreen(self.fullscreen)
end

function SettingsState:set_keybind(action, key)
    for other_action, bound_key in pairs(self.keybinds) do
        if other_action ~= action and bound_key == key then
            self.keybinds[other_action] = nil
        end
    end
    self.keybinds[action] = key
end

function SettingsState:key_map()
    local map = {}
    for action, key in pairs(self.keybinds) do
        if key ~= nil then
            map[action] = {key}
        end
    end
    return map
end

function SettingsState:to_save()
    local keybinds_copy = {}
    for action, key in pairs(self.keybinds) do
        keybinds_copy[action] = key
    end
    return {
        fullscreen = self.fullscreen,
        keybinds   = keybinds_copy,
    }
end

function SettingsState.from_save(data)
    local self = SettingsState.new()
    if type(data) ~= "table" then return self end

    if data.fullscreen == true then
        self:toggle_fullscreen()
    end
    if type(data.keybinds) == "table" then
        for action, key in pairs(data.keybinds) do
            if self.keybinds[action] ~= nil then
                self.keybinds[action] = key
            end
        end
    end

    return self
end

return SettingsState
