local Sprite        = require("core/lua/sprite")
local JobData       = require("game/data/job")
local OutlineShader = require("game/shaders/outline")
local Sound         = require("core/lua/sound")

local SellBin = {}
SellBin.__index = SellBin

function SellBin.new(x, y)
    local self = setmetatable({}, SellBin)
    self._type    = "sell_bin"
    self.x        = x
    self.y        = y
    self.w        = 96
    self.h        = 96
    self.held            = false
    self.carriable       = true
    self.highlighted     = false
    self._outline_shader = OutlineShader.new()
    self.sprite          = Sprite.new(x, y, 96, 96)
    self.sprite.image = love.graphics.newImage("assets/images/sell_bin/sell_bin.png")
    return self
end

-- Attempts to sell the animal against the active jobs in game_state.
-- Returns the reward earned (>0 on success) or 0 on failure.
-- On success: awards money, marks job completed, increments jobs_done and animal_population adjusted by caller.
function SellBin:try_sell(animal, game_state)
    if not game_state:can_sell() then
        return 0
    end

    for _, job in ipairs(game_state.active_jobs) do
        if not job.completed and JobData.Job.test(job, animal.stats) then
            job.completed = true
            game_state.money = game_state.money + job.reward
            game_state.jobs_done = game_state.jobs_done + 1
            game_state.animal_population = game_state.animal_population - 1
            Sound.play("sell_plant")
            return job.reward
        end
    end

    -- No matching job — still sell for a base price of 1
    game_state.money = game_state.money + 1
    game_state.animal_population = game_state.animal_population - 1
    Sound.play("sell_plant")
    return 1
end

function SellBin:update(dt)
    self.sprite.x = self.x
    self.sprite.y = self.y
end

function SellBin:draw()
    if self.highlighted then
        OutlineShader.apply(self._outline_shader, 1, 0.9, 0, 96, 96)
        self.sprite:draw()
        OutlineShader.clear()
    end
    self.sprite:draw()
end

function SellBin:highlight(on)
    self.highlighted = on
end

return SellBin
