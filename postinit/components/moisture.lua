GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")
local Moisture = require("components/moisture")

local _GetMoistureRate = Moisture.GetMoistureRate
function Moisture:GetMoistureRate(...)
    if not TheWorld.state.fullfog then
        return _GetMoistureRate(self, ...)
    end

    return self:_GetMoistureRateAssumingRain() * TUNING.FOG_MOISTURE_RATE_SCALE  -- fog moisture rate
end

local MUST_TAGS = {"blows_air"}
local _GetDryingRate = Moisture.GetDryingRate
function Moisture:GetDryingRate(moisturerate, ...)
    local rate = _GetDryingRate(self, moisturerate, ...)

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, MUST_TAGS)

    if #ents > 0  then
        rate = rate + TUNING.HYDRO_BONUS_COOL_RATE
    end

    return rate
end
