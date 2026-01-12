local MyCharacterMod = RegisterMod("Rouge & Monze", 1)
local game = Game()

-- Definición de personajes
local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local TAINTED_GABRIEL_TYPE = Isaac.GetPlayerTypeByName("Gabriel", true)

-- Definición de disfraces (Costumes)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")

-- IDs de Items
local MOMS_BRACELET_ID = 604
local SUPLEX_ID = 709

-- Rouge stare stats (Configuración del rayo)
local RAY_LENGTH = 1500     -- Largo del rayo
local RAY_WIDTH = 25        -- Ancho del rayo
local DAMAGE_PERCENT = 0.15 -- 15% del daño de lágrimas
local DAMAGE_INTERVAL = 10  -- Cada 10 frames hace daño

-- Función matemática auxiliar (Calcula la distancia de un punto a una línea)
local function GetDistanceFromPointToLine(point, lineStart, lineEnd)
    local lineVec = lineEnd - lineStart
    local pointVec = point - lineStart
    local lineLen = lineVec:Length()

    if lineLen == 0 then return pointVec:Length() end

    local t = pointVec:Dot(lineVec) / (lineLen * lineLen)
    t = math.max(0, math.min(1, t))

    local projection = lineStart + lineVec * t
    return (point - projection):Length()
end

-- Callback: Estadísticas (Velocidad, Daño, etc.)
function MyCharacterMod:HandleStartingStats(player, flag)
    -- Lógica de Rouge (Gabriel Normal)
    if player:GetPlayerType() == gabrielType then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage - 1
        end
        if flag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 2
        end
        if flag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay + 2
        end

        -- Lógica de Monze (Tainted Gabriel)
    elseif player:GetPlayerType() == TAINTED_GABRIEL_TYPE then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + 0.5
        end
        if flag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange - 100
        end
        if flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed - 0.2
        end
        if flag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay + 6
        end
        if flag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck - 2
        end
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyCharacterMod.HandleStartingStats)

-- Callback: Dar disfraces al inicio
function MyCharacterMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then return end

    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.GiveCostumesOnInit)

-- Callback: Inicialización de Tainted Gabriel (Items de bolsillo)
function MyCharacterMod:TaintedGabrielInit(player)
    if player:GetPlayerType() == TAINTED_GABRIEL_TYPE then
        player:SetPocketActiveItem(MOMS_BRACELET_ID, ActiveSlot.SLOT_POCKET, true)
        game:GetItemPool():RemoveCollectible(MOMS_BRACELET_ID)
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.TaintedGabrielInit)

-- Callback: Uso del brazalete
function MyCharacterMod:OnBraceletUse(_, _, player, _, activeSlot)
    if activeSlot == ActiveSlot.SLOT_POCKET then
        player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyCharacterMod.OnBraceletUse, MOMS_BRACELET_ID)

-- Callback: Arreglar items al cambiar de personaje (Ej: Clicker o Lázaro)
function MyCharacterMod:FixItemsOnCharacterSwap(player)
    if player:GetPlayerType() ~= TAINTED_GABRIEL_TYPE then
        if player:HasCollectible(MOMS_BRACELET_ID) then
            player:RemoveCollectible(MOMS_BRACELET_ID)
            if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == MOMS_BRACELET_ID then
                player:SetPocketActiveItem(0, ActiveSlot.SLOT_POCKET, false)
            end
        end
        if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == SUPLEX_ID then
            player:SetPocketActiveItem(0, ActiveSlot.SLOT_POCKET, false)
        end
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyCharacterMod.FixItemsOnCharacterSwap)

-- Callback: Daño invisible (Rayo de Rouge)
function MyCharacterMod:HandleInvisibleRayDamage(player)
    if player:GetPlayerType() ~= gabrielType then return end

    local aimDir = player:GetShootingInput()

    -- Si no está disparando, no hacemos nada
    if aimDir:Length() < 0.1 then return end

    -- Control de frecuencia del daño
    if game:GetFrameCount() % DAMAGE_INTERVAL ~= 0 then return end

    local startPos = player.Position
    local endPos = startPos + (aimDir:Normalized() * RAY_LENGTH)

    -- Busca enemigos en el radio máximo
    local entities = Isaac.FindInRadius(player.Position, RAY_LENGTH + 50, EntityPartition.ENEMY)

    for _, entity in ipairs(entities) do
        if entity:IsVulnerableEnemy() and entity:IsActiveEnemy() and not entity:IsDead() then
            -- Calcula si el enemigo está tocando la línea del disparo
            local dist = GetDistanceFromPointToLine(entity.Position, startPos, endPos)

            if dist < (RAY_WIDTH + entity.Size) then
                -- Calcula el daño (Mínimo 0.15 o el porcentaje del daño del jugador)
                local damageAmount = math.max(0.15, player.Damage * DAMAGE_PERCENT)

                entity:TakeDamage(damageAmount, 0, EntityRef(player), 0)

                -- Efecto visual rojo al golpear
                entity:SetColor(Color(1, 0.5, 0.5, 1, 0, 0, 0), 2, 1, true, false)
            end
        end
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyCharacterMod.HandleInvisibleRayDamage)
