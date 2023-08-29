-- Spawns canopy shadows on specific tiles
-- Was done on the engine in DS so this is based on comments describing what the grid_radius, tile_distance and cull_distance are

--------------------------------------------------------------------------
--[[ RainforestCanopyManager class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local _SpawnShade = SpawnRainforestCanopy
local _DespawnShade = DespawnRainforestCanopy

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------
local GRID_RADIUS = 7		-- number of tiles around player
local CULL_RADIUS = 8		-- grid elements get culled when this many tiles away from the player
local CANOPY_SCALE = 7      -- distance in world units between grid elements
local HALF_CANOPY_SCALE = CANOPY_SCALE * 0.5
local CANOPY_OFFSET = -1

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _isenabled = ShadeRendererEnabled

local _world = TheWorld
local _map = _world.Map
local w, h
local canopy_w, canopy_h
local half_canopy_map_width, half_canopy_map_height
local _canopy_grid

local CANOPY_W_OFFSET
local CANOPY_H_OFFSET

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetCanopyCoordsAtPoint(x, y, z)
    x = math.floor(((x - CANOPY_OFFSET) + CANOPY_W_OFFSET + HALF_CANOPY_SCALE) / CANOPY_SCALE)
    z = math.floor(((z - CANOPY_OFFSET) + CANOPY_H_OFFSET + HALF_CANOPY_SCALE) / CANOPY_SCALE)
    return x, z
end

local function GetCanopyCenterPoint(x, y)
    x = x * CANOPY_SCALE - CANOPY_W_OFFSET + CANOPY_OFFSET
    y = y * CANOPY_SCALE - CANOPY_H_OFFSET + CANOPY_OFFSET
    return x, 0, y
end

local function SpawnShade(cx, cz)
    local x, y, z = GetCanopyCenterPoint(cx, cz)
    _canopy_grid:SetDataAtPoint(cx, cz, _SpawnShade(x, z))
end

local function DespawnShade(cx, cz)
    _DespawnShade(_canopy_grid:GetDataAtPoint(cx, cz))
    _canopy_grid:SetDataAtPoint(cx, cz, nil)
end

local function InitializeDataGrid()
    if _canopy_grid ~= nil then return end --only check one since the rest will all be in the same state

    w, h = _map:GetSize()
    canopy_w, canopy_h = math.ceil((w * TILE_SCALE - CANOPY_OFFSET) / CANOPY_SCALE), math.ceil((h * TILE_SCALE  - CANOPY_OFFSET) / CANOPY_SCALE)
    half_canopy_map_width, half_canopy_map_height = canopy_w * 0.5, canopy_h * 0.5
    _canopy_grid = DataGrid(canopy_w, canopy_h)

    CANOPY_W_OFFSET = CANOPY_SCALE * half_canopy_map_width
    CANOPY_H_OFFSET = CANOPY_SCALE * half_canopy_map_height

    if _isenabled then
        self.inst:StartUpdatingComponent(self)
    end
end
inst:ListenForEvent("worldmapsetsize", InitializeDataGrid, _world)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetEnabled(enable)
    _isenabled = enable
    if enable and _canopy_grid ~= nil then
        self.inst:StartUpdatingComponent(self)
    else
        self.inst:StopUpdatingComponent(self)
    end
end

function self:OnRemoveEntity()
    if _canopy_grid == nil then return end
    for index, data in pairs(_canopy_grid.grid) do
        local _cx, _cz = _canopy_grid:GetXYFromIndex(index)
        DespawnShade(_cx, _cz)
    end
end
self.OnRemoveFromEntity = self.OnRemoveEntity

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local player = ThePlayer
    if player == nil then return end

    local px, py, pz = player.Transform:GetWorldPosition()
    local cx, cz = GetCanopyCoordsAtPoint(px, py, pz)
    local center_x, center_y, center_z = GetCanopyCenterPoint(cx, cz)

    -- cull shade
    for index, data in pairs(_canopy_grid.grid) do
        local _cx, _cz = _canopy_grid:GetXYFromIndex(index)
        if math.abs(cx - _cx) > CULL_RADIUS or math.abs(cz - _cz) > CULL_RADIUS then
            DespawnShade(_cx, _cz)
        end
    end
    
    -- spawn shade
    for x = -GRID_RADIUS, GRID_RADIUS do
        local newx = center_x + (x * CANOPY_SCALE)
        local newcx = cx + x
        for z = -GRID_RADIUS, GRID_RADIUS do
            local newz = center_z + (z * CANOPY_SCALE)
            local newcz = cz + z
            
            local has_shade = _canopy_grid:GetDataAtPoint(newcx, newcz)

            local needs_shade = _map:NodeAtPointHasTag(newx, py, newz, "RainforestCanopy")

            
            if not has_shade and needs_shade then
                SpawnShade(newcx, newcz)
            elseif has_shade and not needs_shade then
                DespawnShade(newcx, newcz)
            end
        end
    end
end

end)
