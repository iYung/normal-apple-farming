local Fonts = require("game/fonts")
local Sound = require("core/lua/sound")

local ITEMS = { "Fullscreen / Window", "Keybinds", "Exit Settings", "Exit to Title" }

local _ACTION_LIST   = {"move_up","move_down","move_left","move_right","interact","pickup"}
local _ACTION_LABELS = {"up","down","left","right","interact","pickup"}

local _MODIFIERS = {
    lshift=true, rshift=true, lctrl=true, rctrl=true,
    lalt=true, ralt=true, lgui=true, rgui=true,
    capslock=true, numlock=true, scrolllock=true
}

local function _all_bound(keybinds)
    for _, action in ipairs(_ACTION_LIST) do
        if keybinds[action] == nil then return false end
    end
    return true
end

local function _joy_nav(input)
    if not input or not input._joystick or not input._joystick:isConnected() then
        return { up=false, down=false, left=false, right=false, confirm=false }
    end
    local joy = input._joystick
    local ax = joy:getGamepadAxis("leftx")
    local ay = joy:getGamepadAxis("lefty")
    return {
        up      = ay < -0.3 or joy:isGamepadDown("dpup"),
        down    = ay >  0.3 or joy:isGamepadDown("dpdown"),
        left    = ax < -0.3 or joy:isGamepadDown("dpleft"),
        right   = ax >  0.3 or joy:isGamepadDown("dpright"),
        confirm = joy:isGamepadDown("a"),
    }
end

local function _visible_items(items, input)
    if input and input._mode == "gamepad" then
        local result = {}
        for _, item in ipairs(items) do
            if item ~= "Keybinds" then
                result[#result + 1] = item
            end
        end
        return result
    end
    return items
end

local W       = 1280
local H       = 720
local BTN_W   = 300
local BTN_H   = 54
local BTN_X   = (W - BTN_W) / 2
local BTN_GAP = 74

local LABEL_W    = 180
local VAL_W      = 110
local BAR_GAP    = 10

local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu

function SettingsMenu.new(settings_state, input, on_close, on_exit_to_title)
    local self = setmetatable({}, SettingsMenu)
    self.is_open = false
    self.selected = 1
    self._prev_up      = false
    self._prev_down    = false
    self._prev_left    = false
    self._prev_right   = false
    self._prev_confirm = false
    self._prev_escape  = false
    self._state = settings_state
    self._input = input
    self._on_close = on_close
    self._on_exit_to_title = on_exit_to_title
    self._subscreen = nil
    self._subscreen_selected = 1
    self._capturing = nil
    self._shake_row   = nil
    self._shake_timer = 0
    self._prev_sub_up      = false
    self._prev_sub_down    = false
    self._prev_sub_confirm = false
    self._prev_sub_escape  = false
    self._img_btn     = love.graphics.newImage("assets/images/menu_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/images/menu_btn_selected.png")
    self._img_bg_opaque = love.graphics.newImage("assets/images/settings_background.png")
    self._font_btn    = Fonts.new(22)
    self._font_vol    = Fonts.new(15)
    self._sub_btn_y0  = H / 2 - #_ACTION_LIST * BTN_GAP / 2 - BTN_H / 2  -- centres 5 sub-screen rows
    return self
end

function SettingsMenu:open(opaque)
    self.is_open  = true
    self._opaque  = opaque or false
    self.selected = 1
    self._subscreen = nil
    self._capturing = nil
    -- Snapshot current key state so keys held at open time don't immediately fire
    local kb = self._state.keybinds
    self._prev_up      = love.keyboard.isDown("up")    or love.keyboard.isDown(kb.move_up    or "w")
    self._prev_down    = love.keyboard.isDown("down")  or love.keyboard.isDown(kb.move_down  or "s")
    self._prev_left    = love.keyboard.isDown("left")  or love.keyboard.isDown(kb.move_left  or "a")
    self._prev_right   = love.keyboard.isDown("right") or love.keyboard.isDown(kb.move_right or "d")
    self._prev_confirm = love.keyboard.isDown(kb.interact or "e")
                      or love.keyboard.isDown("return")
    self._prev_escape  = love.keyboard.isDown("escape")
    -- Also snapshot gamepad state to prevent ghost-fire on open
    local _jn = _joy_nav(self._input)
    self._prev_up      = self._prev_up      or _jn.up
    self._prev_down    = self._prev_down    or _jn.down
    self._prev_left    = self._prev_left    or _jn.left
    self._prev_right   = self._prev_right   or _jn.right
    self._prev_confirm = self._prev_confirm or _jn.confirm
    local joy = self._input and self._input._joystick
    self._prev_escape = self._prev_escape
        or (joy ~= nil and joy:isConnected() and joy:isGamepadDown("start"))
end

function SettingsMenu:close()
    self.is_open = false
    if self._on_close then self._on_close() end
end

function SettingsMenu:update(dt)
    if self._shake_timer > 0 then
        self._shake_timer = math.max(0, self._shake_timer - dt)
        if self._shake_timer == 0 then self._shake_row = nil end
    end

    if self._subscreen == "keybinds" then
        if self._capturing ~= nil then
            return
        end

        local up      = love.keyboard.isDown("up")   or love.keyboard.isDown(self._state.keybinds.move_up   or "w")
        local down    = love.keyboard.isDown("down") or love.keyboard.isDown(self._state.keybinds.move_down or "s")
        local confirm = love.keyboard.isDown(self._state.keybinds.interact or "e")
                     or love.keyboard.isDown("return")
        local escape  = love.keyboard.isDown("escape")

        -- OR in gamepad nav for keybinds sub-screen
        local _jn = _joy_nav(self._input)
        up      = up      or _jn.up
        down    = down    or _jn.down
        confirm = confirm or _jn.confirm
        local joy = self._input and self._input._joystick
        escape = escape
            or (joy ~= nil and joy:isConnected() and joy:isGamepadDown("start"))

        local sub_count = #_ACTION_LIST + 1
        if up and not self._prev_sub_up then
            self._subscreen_selected = ((self._subscreen_selected - 2) % sub_count) + 1
            Sound.play("menu_navigate")
        end
        if down and not self._prev_sub_down then
            self._subscreen_selected = (self._subscreen_selected % sub_count) + 1
            Sound.play("menu_navigate")
        end
        if confirm and not self._prev_sub_confirm then
            if self._subscreen_selected == sub_count then
                if _all_bound(self._state.keybinds) then
                    self._subscreen = nil
                end
            else
                self._capturing = _ACTION_LIST[self._subscreen_selected]
            end
        end
        if escape and not self._prev_sub_escape then
            if _all_bound(self._state.keybinds) then
                self._subscreen = nil
            end
        end

        self._prev_sub_up      = up
        self._prev_sub_down    = down
        self._prev_sub_confirm = confirm
        self._prev_sub_escape  = escape
        return
    end

    local kb = self._state.keybinds
    local up      = love.keyboard.isDown("up")    or love.keyboard.isDown(kb.move_up    or "w")
    local down    = love.keyboard.isDown("down")  or love.keyboard.isDown(kb.move_down  or "s")
    local confirm = love.keyboard.isDown(kb.interact or "e")
                 or love.keyboard.isDown("return")
    local escape  = love.keyboard.isDown("escape")

    -- OR in gamepad nav for main menu
    local _jn = _joy_nav(self._input)
    up      = up      or _jn.up
    down    = down    or _jn.down
    confirm = confirm or _jn.confirm
    local joy = self._input and self._input._joystick
    escape = escape
        or (joy ~= nil and joy:isConnected() and joy:isGamepadDown("start"))

    -- Clamp selected to visible items (in case mode changed while open)
    local vis = _visible_items(ITEMS, self._input)
    local selected_item = ITEMS[self.selected]
    local selected_visible = false
    for _, item in ipairs(vis) do
        if item == selected_item then selected_visible = true; break end
    end
    if not selected_visible then
        self.selected = 1
    end

    if up and not self._prev_up then
        -- Navigate up through visible items
        local cur_vis_idx = 1
        for j, item in ipairs(vis) do
            if item == ITEMS[self.selected] then cur_vis_idx = j; break end
        end
        local new_vis_idx = ((cur_vis_idx - 2) % #vis) + 1
        -- Find ITEMS index for the new visible item
        for k, v in ipairs(ITEMS) do
            if v == vis[new_vis_idx] then self.selected = k; break end
        end
        Sound.play("menu_navigate")
    end
    if down and not self._prev_down then
        -- Navigate down through visible items
        local cur_vis_idx = 1
        for j, item in ipairs(vis) do
            if item == ITEMS[self.selected] then cur_vis_idx = j; break end
        end
        local new_vis_idx = (cur_vis_idx % #vis) + 1
        -- Find ITEMS index for the new visible item
        for k, v in ipairs(ITEMS) do
            if v == vis[new_vis_idx] then self.selected = k; break end
        end
        Sound.play("menu_navigate")
    end
    if confirm and not self._prev_confirm then
        self:_confirm()
    end
    if escape and not self._prev_escape then
        self:close()
    end

    self._prev_up      = up
    self._prev_down    = down
    self._prev_left    = love.keyboard.isDown("left")  or love.keyboard.isDown(kb.move_left  or "a")
    self._prev_right   = love.keyboard.isDown("right") or love.keyboard.isDown(kb.move_right or "d")
    self._prev_confirm = confirm
    self._prev_escape  = escape
end

function SettingsMenu:_confirm()
    Sound.play("menu_confirm")
    if self.selected == 1 then
        self._state:toggle_fullscreen()
    elseif self.selected == 2 then
        -- Guard: skip Keybinds in gamepad mode (not reachable via navigation, but defensive)
        if self._input and self._input._mode == "gamepad" then
            return
        end
        self._subscreen = "keybinds"
        self._subscreen_selected = 1
        -- Snapshot so keys held at transition time don't immediately fire in the sub-screen
        self._prev_sub_up      = love.keyboard.isDown("up")   or love.keyboard.isDown(self._state.keybinds.move_up   or "w")
        self._prev_sub_down    = love.keyboard.isDown("down") or love.keyboard.isDown(self._state.keybinds.move_down or "s")
        self._prev_sub_confirm = love.keyboard.isDown(self._state.keybinds.interact or "e")
                              or love.keyboard.isDown("return")
        self._prev_sub_escape  = love.keyboard.isDown("escape")
    elseif self.selected == 3 then
        self:close()
    elseif self.selected == 4 then
        self.is_open = false
        if self._on_exit_to_title then
            self._on_exit_to_title()
        end
    end
end

function SettingsMenu:keypressed(key)
    if self._subscreen == "keybinds" and self._capturing == nil then
        if key == "escape" then
            if _all_bound(self._state.keybinds) then
                self._subscreen = nil
                return true
            end
            return false
        end
        return false
    end
    if self._capturing == nil then return false end
    if key == "escape" then
        self._capturing = nil
        return true
    end
    if _MODIFIERS[key] then return false end
    for i, action in ipairs(_ACTION_LIST) do
        if action ~= self._capturing and self._state.keybinds[action] == key then
            self._shake_row   = i
            self._shake_timer = 0.5
            return true
        end
    end
    self._state:set_keybind(self._capturing, key)
    self._input._map = self._state:key_map()
    self._input._map.cancel = {"escape"}
    self._capturing = nil
    return true
end

function SettingsMenu:gamepadpressed(button)
    if button ~= "start" then return false end
    if self._subscreen == "keybinds" and self._capturing == nil then
        if _all_bound(self._state.keybinds) then
            self._subscreen = nil
            return true
        end
        return false
    end
    if self._capturing ~= nil then
        self._capturing = nil
        return true
    end
    self:close()
    return true
end

function SettingsMenu:draw()
    local prev_font = love.graphics.getFont()

    if self._subscreen == "keybinds" then
        -- Background
        if self._opaque then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self._img_bg_opaque, 0, 0)
        else
            love.graphics.setColor(0, 0, 0, 0.55)
            love.graphics.rectangle("fill", 0, 0, W, H)
        end

        local sub_count = #_ACTION_LIST + 1
        love.graphics.setFont(self._font_btn)
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, #_ACTION_LIST do
            local ox = 0
            local row_r, row_g, row_b = 1, 1, 1
            if self._shake_row == i and self._shake_timer > 0 then
                ox = math.sin(self._shake_timer * 40) * 8 * (self._shake_timer / 0.5)
                row_r, row_g, row_b = 1, 0.25, 0.25
            end
            local y = self._sub_btn_y0 + (i - 1) * BTN_GAP
            local img = i == self._subscreen_selected and self._img_btn_sel or self._img_btn
            local ty = y + (BTN_H - self._font_btn:getHeight()) / 2
            -- Label bar
            love.graphics.setColor(row_r, row_g, row_b, 1)
            love.graphics.draw(img, BTN_X + ox, y, 0, LABEL_W / BTN_W, 1)
            love.graphics.printf(_ACTION_LABELS[i], BTN_X + ox, ty, LABEL_W, "center")
            -- Value bar
            love.graphics.draw(img, BTN_X + LABEL_W + BAR_GAP + ox, y, 0, VAL_W / BTN_W, 1)
            if self._capturing == _ACTION_LIST[i] then
                love.graphics.printf("hit key", BTN_X + LABEL_W + BAR_GAP + ox, ty, VAL_W, "center")
            elseif self._state.keybinds[_ACTION_LIST[i]] then
                love.graphics.printf(self._state.keybinds[_ACTION_LIST[i]]:upper(), BTN_X + LABEL_W + BAR_GAP + ox, ty, VAL_W, "center")
            else
                love.graphics.setFont(self._font_vol)
                local vty = y + (BTN_H - self._font_vol:getHeight()) / 2
                love.graphics.printf("UNBOUND", BTN_X + LABEL_W + BAR_GAP + ox, vty, VAL_W, "center")
                love.graphics.setFont(self._font_btn)
            end
        end

        local ry     = self._sub_btn_y0 + #_ACTION_LIST * BTN_GAP
        local all_ok = _all_bound(self._state.keybinds)
        if not all_ok then
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.draw(self._img_btn, BTN_X, ry)
            love.graphics.printf("Return", BTN_X, ry + (BTN_H - self._font_btn:getHeight()) / 2, BTN_W, "center")
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(self._font_vol)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("all keys must be bound", BTN_X, ry + BTN_H + 6, BTN_W, "center")
            love.graphics.setFont(self._font_btn)
            love.graphics.setColor(1, 1, 1, 1)
        else
            local img = sub_count == self._subscreen_selected and self._img_btn_sel or self._img_btn
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, BTN_X, ry)
            love.graphics.printf("Return", BTN_X, ry + (BTN_H - self._font_btn:getHeight()) / 2, BTN_W, "center")
        end

        love.graphics.setFont(prev_font)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Background: opaque image when the title/start scene is behind us,
    -- semi-transparent overlay when opened mid-game
    if self._opaque then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self._img_bg_opaque, 0, 0)
    else
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, W, H)
    end

    love.graphics.setFont(self._font_btn)
    local vis = _visible_items(ITEMS, self._input)
    local btn_y0 = H / 2 - (#vis - 1) * BTN_GAP / 2 - BTN_H / 2
    for j, item in ipairs(vis) do
        local i = 0
        for k, v in ipairs(ITEMS) do if v == item then i = k; break end end
        local y   = btn_y0 + (j - 1) * BTN_GAP
        local img = (i == self.selected) and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, BTN_X, y)

        local th = self._font_btn:getHeight()
        local ty = y + (BTN_H - th) / 2
        if i == 1 then
            love.graphics.printf(self._state.fullscreen and "Window" or "Fullscreen", BTN_X, ty, BTN_W, "center")
        else
            love.graphics.printf(ITEMS[i], BTN_X, ty, BTN_W, "center")
        end
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return SettingsMenu
