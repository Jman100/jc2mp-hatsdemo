--[[
	Hat demonstration script
	Created by Jman100 (with a little help from Philpax)
--]]

hatcount = 0
enabled = true
player_hats = {} -- Create a table for storing created hats (ClientStaticObjects)

-- Table of hat models (This is only a small list, more are available)
hats = {
	"pd_arcticvillage_male1.eez/pd_arcticvillage_male-hat.lod",
	"pd_arcticvillage_female1.eez/pd_arcticvillage_female-headcloth.lod",
	"pd_arcticvillage_female1.eez/pd_arcticvillage_female-headcloth2.lod",
	"pd_arcticvillage_female2.eez/pd_arcticvillage_female_2-hat_winter.lod",
	"pd_arcticvillage_male2.eez/pd_arcticvillage_male_2-hat_winter.lod",
	"pd_blackmarket.eez/pd_blackmarket-scarf.lod",
	"pd_desertvillage_female1.eez/pd_desertvillage_female-shawl.lod", 
	"pd_desertvillage_male1.eez/pd_desertvillage_male-turban.lod",
	"pd_fishervillage_male1.eez/pd_fishervillage_male-hat_fisherman.lod",
	"pd_fishervillage_male1.eez/pd_fishervillage_male-ricehat.lod",
	"pd_generic_female.eez/generic_female-ricehat.lod",
	"pd_generic_female.eez/generic_female-shawl.lod", 
	"pd_generic_female_1.eez/pd_generic_female_1-hat_linen.lod",
	"pd_generic_female_1.eez/pd_generic_female_1-hat_rice.lod",
	"pd_generic_female_2.eez/pd_generic_female_2-hat_linen.lod",
	"pd_generic_female_2.eez/pd_generic_female_2-hat_rice.lod", 
	"pd_generic_female_2.eez/pd_generic_female_2-hat_towel.lod",
	"pd_generic_female_3.eez/pd_generic_female_3-hat_scarf.lod", 
	"pd_generic_female_3.eez/pd_generic_female_3-hat_straw2.lod",
}

function ChangeHat(dir)	
	hatcount = hatcount + dir
	
	if hatcount > #hats then hatcount = 1 end -- If we reach the end of the list, go back to 1
	if hatcount == 0 then hatcount = #hats end

	local hatmodel = hats[hatcount] -- Get the current hat model from table of hats
	Network:Send( "ChangeHat", hatmodel ) -- Send the hat model to the server script so it can be stored in the player value
end

function MoveHat(player)
	if IsValid(player) then
		local hat = player_hats[player:GetId()]

		if hat ~= nil and IsValid(hat) then
			-- Set the angle of the hat on every render frame
			hat:SetAngle(player:GetBoneAngle("ragdoll_Head"))
			
			-- Create offsets from the default positioning of the hat to better fit over player models heads
			-- This offset doesn't perfectly work for all player models. Tweaking may be necessary.
			local hatoffset = hat:GetAngle() * Vector3(0,1.62,.03)
			
			-- Set the position of the hat on every render frame
			hat:SetPosition(player:GetBonePosition("ragdoll_Head") - hatoffset) 
		end
	end
end

function RenderTick()
	for p in Client:GetStreamedPlayers() do
		MoveHat(p)
	end

	MoveHat(LocalPlayer)	

	if enabled then
		-- Render help text
		local text = "Left/Right change hats. Current hat: " .. hatcount .. " / " .. #hats
		Render:DrawText(Vector2(Render.Width / 2 - (Render:GetTextWidth(text, TextSize.Large) / 2), Render.Height - 100), text, Color(255,255,255), TextSize.Large)
	end
end

-- Load new hat when /hat is typed
function KDown(args)
	if enabled then
		if args.key == 37 then
			ChangeHat(-1)
		elseif args.key == 39 then
			ChangeHat(1)
		end
	end
end

function LocalPlayerChat(args) -- Enable/disable hat changer by typing /hat
	if args.text == "/hat" then
		enabled = not enabled
		Chat:Print( "Hat mode status: " .. tostring(enabled), Color.OrangeRed )
	end
end

function DestroyHat(player)
	if player_hats[player:GetId()] ~= nil then
		if IsValid( player_hats[player:GetId()], false ) then
			player_hats[player:GetId()]:Remove()
		end
		player_hats[player:GetId()] = nil
	end
end

function CreateHat(player)
	DestroyHat(player)	

	local hatModel = player:GetValue("HatModel")

	if hatModel == nil or #hatModel == 0 then return end
	
	-- Create the hat
	player_hats[player:GetId()] = ClientStaticObject.Create({
		position = player:GetBonePosition("ragdoll_Head"), -- Place the hat at the model's head
		angle = player:GetBoneAngle("ragdoll_Head"), -- Angle the hat at the same angle of the model's head
		model = hatModel
	})
end

-- Event to detect when the hat model is changed (serverside) and (re)create the hat
function PlayerValueChange(args)
	if args.key ~= "HatModel" then return end

	CreateHat(args.player)
end

-- Event to detect when a player is spawned to create a new hat for that player (from the perspective of the LocalPlayer)
function EntitySpawn(args)
	if args.entity.__type == "Player" then
		CreateHat(args.entity)
	end
end

-- Event to detect when a player is despawned to remove the existing hat (from the perspective of the LocalPlayer)
function EntityDespawn(args)
	if args.entity.__type == "Player" then
		DestroyHat(args.entity)
	end
end

-- On load of script (or player connect), create hats for all players in the server
function ModuleLoad()
	for p in Client:GetStreamedPlayers() do
		CreateHat(p)
	end

	CreateHat(LocalPlayer)
end

-- Remove the hat when the script is unloaded (or player disconnects)
function ModuleUnload()
	for k, v in pairs(player_hats) do
		if IsValid(v, false) then
			v:Remove()
		end
	end
end

-- Subscribe to our events
Events:Subscribe("Render", RenderTick)
Events:Subscribe("KeyDown", KDown)
Events:Subscribe("LocalPlayerChat", LocalPlayerChat)
Events:Subscribe("PlayerNetworkValueChange", PlayerValueChange)

Events:Subscribe("EntitySpawn", EntitySpawn)
Events:Subscribe("EntityDespawn", EntityDespawn)

Events:Subscribe("ModuleLoad", ModuleLoad)
Events:Subscribe("ModuleUnload", ModuleUnload)

ChangeHat(1) -- Create the first hat
