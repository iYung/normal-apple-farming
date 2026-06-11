local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self = setmetatable({}, GameState)
    self.money          = 0       -- current money balance
    self.wires          = 5       -- wire inventory (Roll items place these)
    self.jobs_done      = 0       -- total jobs completed (drives job generator unlocks)
    self.active_jobs    = {}      -- array of Job tables (max 4 at once)
    self.animal_population = 2    -- tracks living animals (must stay > 2 to sell)
    return self
end

-- Returns true if the player is allowed to sell an animal.
-- Must have more than 2 animals alive (keep at least 2 for breeding).
function GameState:can_sell()
    return self.animal_population > 2
end

return GameState
