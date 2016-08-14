AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

util.AddNetworkString("ragcom_msg")
util.AddNetworkString("ragcom_sound")
util.AddNetworkString("ragcom_gui")
util.AddNetworkString("ragcom_select_char")
util.AddNetworkString("ragcom_wins")

net.Receive("ragcom_select_char",function(_,ply)
	local n = net.ReadUInt(8)
	ply.char = n
	ply:SetNWInt("rcplychar", n)
	if n == 0 then
		--ply.RagdollItem = nil
		if (ply.RagdollItem) then
			ply:PS_HolsterFromCategory(ply.RagdollItem.Category)
		end
	end
	
	--ply:ChatPrint("Character selected!")
end)

local function gm_msg(str,col)
	if game.IsDedicated() then print(">>",str) end
	net.Start("ragcom_msg")
	net.WriteString(str)
	net.WriteColor(col)
	net.Broadcast()
end






local SpawnTypes = {"info_player_start", "info_player_deathmatch", "info_player_combine",
"info_player_rebel", "info_player_counterterrorist", "info_player_terrorist",
"info_player_axis", "info_player_allies", "gmod_player_start",
"info_player_teamspawn"}


local function GetSpawnEnts()
   local tbl = {}
   for k, classname in pairs(SpawnTypes) do
      for _, e in pairs(ents.FindByClass(classname)) do
         if IsValid(e) and (not e.BeingRemoved) then
            table.insert(tbl, e)
         end
      end
   end

   return tbl
end

local function getSpawnHeight()
	if game.GetMap() == "ragcom_highway_valley" then
		return 1280.031250
	else
		local spawntbl = GetSpawnEnts()
		local spawn = spawntbl[1]
		local pos = spawn:GetPos()
		return pos.z
	end
	
	return 0
end
local currSpawnHeight = nil


local function getResetViewPosition()

	local vec =  Vector(1166,1065,-11889)
	
	local spawntbl = GetSpawnEnts()
	local spawn = spawntbl[1]
	if (spawn) then
		vec = spawn:GetPos()
	end
	
	return vec
end


local function rocketman(ply)
	--print("prepping for launch")
	if IsValid(ply) and IsValid(ply.controller) and !ply.controller.rocketed then
		ply.controller.rocketed=true
		ply.controller.limp_timer=10
		ply.controller:EmitSound("npc/env_headcrabcanister/launch.wav")
		--shamelessly stolen from old wiki
		local trailent = util.SpriteTrail(ply.controller, 0, Color(255,0,0), false, 15, 1, 4, 1/(15+1)*0.5, "trails/plasma.vmt")
		SafeRemoveEntityDelayed( trailent, 10 ) 
		
		local ragdoll = ply.controller:GetRagdoll()
		local v = Vector(0,0,10000)+VectorRand()*5000
		for i=1, ragdoll:GetPhysicsObjectCount() do
			ragdoll:GetPhysicsObjectNum(i-1):SetVelocity(v)	
		end
		
		--failsafe
		--timer.Simple(8,function() if IsValid(ply.controller) and ply.controller.rocketed then SafeRemoveEntity( ply.Trail ) end end)
	end
end



local function spawn_doll(ply,n,r)
	local ragdoll_control = ents.Create("ragcom_controller")
	local h = getSpawnHeight() -- -12260
	ragdoll_control:SetPos(Vector(math.sin(n)*r,math.cos(n)*r,h))
	ragdoll_control:SetController(ply)
	ragdoll_control:SetChar(ply.char)
	print("spawning ",ply," ", ply.char)
	ragdoll_control:Spawn()
end

local function resetView(ply)
	--ply:SetPos(Vector(1166,1065,-11889))
	
	ply:SetPos(getResetViewPosition())
	ply:SetEyeAngles(Angle(28,-138,0))
end

--I'm sorry ):
if RAGCOM_ROUND_RUNNING==nil then
	RAGCOM_ROUND_RUNNING = false
end

if RAGCOM_GAME_RUNNING==nil then
	RAGCOM_GAME_RUNNING = false
end

if RAGCOM_ROUND_N==nil then
	RAGCOM_ROUND_N=1
end

local function get_non_spectators()
	local t = {}
	for _,ply in pairs(player.GetAll()) do
		if ply.RagdollItem or ply:IsBot() then
			table.insert(t,ply)
		end
	end
	return t
end

local last_ko=CurTime()
local last_ko2=CurTime()
local last_winner = nil

local function round_start()


	for _,ply in pairs(player.GetAll()) do
		ply.hasbrick = 0
		ply:SetNWInt("hasbrick", ply.hasbrick)
	end
	
	last_ko = CurTime()
	last_ko2 = CurTime()
	gm_msg("Round #"..RAGCOM_ROUND_N..": Fight!",Color(50,50,255))
	RAGCOM_ROUND_N=RAGCOM_ROUND_N+1
	RAGCOM_ROUND_RUNNING = true
	local players = get_non_spectators()
	
	local plug = 60 - #players
	--if game.GetMap() == "gm_flatgrass" then
	--	plug = 30
	--end
	--if (#players > 20 and 
--		plug = 30
	--end
	
	for k,v in pairs(players) do
		local n = (k/#players)*6.28
		spawn_doll(v,n,#players * plug)
		v:SetEyeAngles(Angle(0,-90-math.deg(n),0))
	end
end

local function round_end()
	RAGCOM_ROUND_RUNNING = false
	timer.Simple(5,function()
		local players = get_non_spectators()
		for k,v in pairs(players) do
			v.hasbrick=0
			if IsValid(v.controller) then
				v.controller:Remove()
				--resetView(v)
			end
		end
		if #players>=2 then
			timer.Simple(1,round_start)
		else
			RAGCOM_GAME_RUNNING=false
			gm_msg("Not enough players to continue combat. Waiting...",Color(50,50,255))
		end
	end)
end

function GM:PlayerInitialSpawn(ply)
	if ply:IsBot() then
		ply.char=math.random(#RAGCOM_CHARS)
	else
		ply.char=0 --math.random(#RAGCOM_CHARS)
		ply.RagdollItem = nil
		ply.hasbrick = 0
		ply:SetNWInt("hasbrick", ply.hasbrick)
	end
	
	ply.ragcom_wins = 0

	if not ply:IsBot() then
		for _,v in pairs(player.GetAll()) do
			if v.ragcom_wins != nil then
				net.Start("ragcom_wins")
				net.WriteEntity(v)
				net.WriteInt(v.ragcom_wins,16)
				net.Send(ply)
			end
		end
	end
end

function GM:KeyPress(ply, key)
	--print(key)
	if IsValid(ply.controller) then
		if key==IN_ATTACK then
			ply.controller.ctrl_attack_1 = true
		elseif key==IN_ATTACK2 then
			ply.controller.ctrl_attack_2 = true
		elseif key==IN_JUMP then
			ply.controller.ctrl_jump = true
		--elseif key==IN_WALK  then
		--	rocketman(ply)
		elseif key==  IN_SPEED then
			ply.controller.ctrl_kick = true
		elseif key== IN_WALK  then
			ply.controller.ctrl_butt = true
		end	
	elseif key==IN_ATTACK and (ply.hasbrick > 0 or ply:IsSuperAdmin() or RAGCOM_ROUND_RUNNING == false) then
		ply.hasbrick=ply.hasbrick - 1
		ply:SetNWInt("hasbrick", ply.hasbrick)
		
		local block = nil
		if (ply.ThrowableProp == nil) then
			block = ents.Create("prop_physics")
			block:SetModel("models/props_junk/cinderblock01a.mdl")
			block:SetPos(ply:GetPos())
			--block:SetMaterial("models/debug/debugwhite")
			--block:SetColor(Color(100,100,100))
			block:Spawn()
			local phys = block:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(ply:EyeAngles():Forward()*1000)
			end
		else
		
			if ply.ThrowableProp.IsRagdoll then
				block = ents.Create("prop_ragdoll")
			else
				block = ents.Create("prop_physics")
			end
			
			block:SetModel(ply.ThrowableProp.Model)
			block:SetPos(ply:GetPos())
			
			if (ply.ThrowableProp.Scale) then
				block:SetModelScale(ply.ThrowableProp.Scale,0)
			end
			
			if (ply.ThrowableProp.PreSetup) then
				ply.ThrowableProp:PreSetup(block)
			end
			
			block:Spawn()
			block:Activate()
			
			if (ply.ThrowableProp.Setup) then
				ply.ThrowableProp:Setup(block)
			end
			
			local phys = block:GetPhysicsObject()
			if IsValid(phys) then
				if (ply.ThrowableProp.Mass) then
					phys:SetMass( ply.ThrowableProp.Mass )
				end
				phys:SetVelocity(ply:EyeAngles():Forward()*1000)
			end
			
			
		end
		
		
		
		
		
		
		
		--if IsValid(block) then
			local tmr = 6
			if (RAGCOM_ROUND_RUNNING == false) then tmr = 2 end
			timer.Simple(tmr,function() if IsValid(block) then block:Remove() end end)
		--end
	end 
end

-- No spawning allowed!
function GM:PlayerSpawn(ply)
	ply:KillSilent()
	ply:Spectate(OBS_MODE_ROAMING)
	resetView(ply)
end

function GM:PlayerDeathThink(ply)
	return false
end

local nextThinkCheck = CurTime()
function GM:Think()

	
	if nextThinkCheck > CurTime() then return end
	nextThinkCheck = CurTime() + 1.0
	
	if currSpawnHeight == nil then
		currSpawnHeight = getSpawnHeight()
	end

	local plycnt = #get_non_spectators()
	
	if not RAGCOM_GAME_RUNNING and plycnt>=2 then
		gm_msg("Let the combat begin!",Color(50,50,255))
		RAGCOM_GAME_RUNNING=true
		round_start()
	end

	if not RAGCOM_ROUND_RUNNING then return end
	local controllers = ents.FindByClass("ragcom_controller")

	if #controllers==1 then
		local ply = controllers[1]:GetController()
		controllers[1]:WinTaunt()
		ply.ragcom_wins = ply.ragcom_wins + 1
		
		net.Start("ragcom_wins")
		net.WriteEntity(ply)
		net.WriteInt(ply.ragcom_wins,16)
		net.Broadcast()

		gm_msg(ply:GetName().." won the round!",Color(50,255,50))
		if plycnt > 4 then ply:PS_GivePoints(1000) end
		last_winner = ply
		round_end()
	elseif #controllers==0 then
		gm_msg("Evidently there's nobody left so I guess it's time to reset.",Color(50,255,50))
		round_end()
	end

	for k,ent in pairs(controllers) do
		if (ent:GetPos().z<-12700 or ent:GetPos().z < currSpawnHeight - 6000) and not ent.ready_die then
			ent.ready_die = true
			ent.limp_timer = 2
			
			local killer
			
			if IsValid(ent.last_attacker) and ent.last_attacker:IsPlayer() then
				killer = ent.last_attacker:Nick()
				ent.last_attacker:AddFrags(1)
			end
			
			timer.Simple(.5,function()
				if not IsValid(ent) or ent.won then return end
				local ed = EffectData()
				ed:SetOrigin(ent:GetPos())
				util.Effect("HelicopterMegaBomb",ed)

				--EmitSound("", Vector position, number entity, number channel=CHAN_AUTO, number volume=1, number soundLevel=75, number soundFlags=0, number pitch=100 )
				sound.Play("weapons/physcannon/energy_sing_explosion2.wav",ent:GetPos(),100,50,.5)

				local ply = ent:GetController()

				ent:Remove()
				
				if killer then
					gm_msg(ply:GetName().." was KTFO'd by "..killer.."!",Color(255,50,50))
				else
					gm_msg(ply:GetName().." was KTFO'd!",Color(255,50,50))
				end

				
				resetView(ply)
			end)
		end
	end

	--brickage
	
	local plug = 45
	if (plycnt > 20) then
		plug = 60
	end
	
	if last_ko + plug < CurTime() then
		last_ko = CurTime()
		gm_msg("This is getting boring! Spectators have been given things to throw at fighters!",Color(255,50,50))
		for k,v in pairs(player.GetAll()) do
			if !IsValid(v.controller) and v.hasbrick < 3 then
				v.hasbrick=v.hasbrick + 1
				v:SetNWInt("hasbrick", v.hasbrick)
			end		
		end
	end
	
	if IsValid(last_winner) and !IsValid(last_winner.controller) and last_winner.hasbrick < 3 and last_ko2 + 10 < CurTime() then
		last_ko2 = CurTime()
		last_winner.hasbrick=last_winner.hasbrick+1
		last_winner:SetNWInt("hasbrick", last_winner.hasbrick)
	end
		
end

function GM:ShowHelp(ply)
	net.Start("ragcom_gui")
	net.WriteInt(1,8)
	net.Send(ply)
end

function GM:ShowSpare2(ply)
	--net.Start("ragcom_gui")
	--net.WriteInt(2,8)
	--net.Send(ply)
	rocketman(ply)
end



concommand.Add("ragcom_rocket",function(ply)
	rocketman(ply)
end)

concommand.Add("ragcom_rocket_afk",function(ply)
	if IsValid(ply) and IsValid(ply.controller) and !ply.controller.rocketed then
		ply.controller.rocketed=true
		ply.controller.limp_timer=100
		ply.controller:EmitSound("npc/env_headcrabcanister/launch.wav")
		--shamelessly stolen from old wiki
		util.SpriteTrail(ply.controller, 0, Color(255,0,0), false, 15, 1, 4, 1/(15+1)*0.5, "trails/plasma.vmt")

		local ragdoll = ply.controller:GetRagdoll()
		local v = Vector(0,0,10000)+VectorRand()*5000
		for i=1, ragdoll:GetPhysicsObjectCount() do
			ragdoll:GetPhysicsObjectNum(i-1):SetVelocity(v)	
		end
		
		--failsafe
		timer.Simple(8,function() if IsValid(ply.controller) and ply.controller.rocketed then ply.controller:Remove() end end)
	end
end)





