local mod = SegmentedMausoleum

function mod:KnifeUpdate(entity)
    local player = entity.SpawnerEntity:ToPlayer()
    if player:HasCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_3) then
         if entity:IsDead() then
            local knife = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.KNIFE_FULL, 0, entity.Position, Vector.Zero, player):ToFamiliar()
        end
    end
end

mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.KnifeUpdate, FamiliarVariant.KNIFE_FULL)