local mod = SegmentedMausoleum

function mod:onEvaluateCache(player)
	local numFamiliars = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_KNIFE_PIECE_3) + player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_KNIFE_PIECE_3)
	
	player:CheckFamiliar(215, numFamiliars, player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_KNIFE_PIECE_3), Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_3))	
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.onEvaluateCache, CacheFlag.CACHE_FAMILIARS)

function mod:familiarInit(familiar)
	familiar:AddToFollowers()
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.familiarInit, 215)

function mod:familiarUpdate(familiar)
	familiar:FollowParent()
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.familiarUpdate, 215)