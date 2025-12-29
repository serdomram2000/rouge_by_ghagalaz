local MyCharacterMod = RegisterMod("Rouge & Monze", 1)
local game = Game()

local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local TAINTED_GABRIEL_TYPE = Isaac.GetPlayerTypeByName("Gabriel", true)

local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")

local MOMS_BRACELET_ID = 604
local SUPLEX_ID = 709

function MyCharacterMod:HandleStartingStats(player, flag)

    -- Rouge logic
    if player:GetPlayerType() == gabrielType then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage - 1.5
        end

        if flag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 2
        end

    -- Monze logic
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

function MyCharacterMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then
        return
    end

    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.GiveCostumesOnInit)

function MyCharacterMod:TaintedGabrielInit(player)
    if player:GetPlayerType() == TAINTED_GABRIEL_TYPE then
        player:SetPocketActiveItem(MOMS_BRACELET_ID, ActiveSlot.SLOT_POCKET, true)
        
        local pool = game:GetItemPool()
        pool:RemoveCollectible(MOMS_BRACELET_ID)
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.TaintedGabrielInit)

function MyCharacterMod:OnBraceletUse(_, _, player, _, activeSlot)
    if activeSlot == ActiveSlot.SLOT_POCKET then
        player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyCharacterMod.OnBraceletUse, MOMS_BRACELET_ID)

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