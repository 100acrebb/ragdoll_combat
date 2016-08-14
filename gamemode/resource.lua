AddCSLuaFile()

local textures = {
	"ragcom/spudz_face",
	"ragcom/spudz_body",
	"ragcom/pow_face",
	"ragcom/pow_body",
	"ragcom/pow_hair",
	"ragcom/shia_face",
	"ragcom/shia_body",
	"ragcom/postal_face",
	"ragcom/postal_body",
	"ragcom/critter_face",
	"ragcom/critter_body",
	"ragcom/critter_hat"
}

if SERVER then
	for k,v in pairs(textures) do
		resource.AddSingleFile("materials/"..v..".png")
	end
	resource.AddSingleFile("sound/ragcom/shia_win.wav")
	resource.AddSingleFile("sound/ragcom/postal_win.wav")
	resource.AddSingleFile("sound/ragcom/postal_fall.wav")
	resource.AddSingleFile("sound/ragcom/and-his-name-is-john-cena-1.mp3")
end

RAGCOM_MATS = {}

for k,v in pairs(textures) do
	local m = Material(v..".png")
	if CLIENT then CreateMaterial("ragcom_"..k,"VertexLitGeneric",{["$basetexture"] = v}) end
	RAGCOM_MATS[v] = "!ragcom_"..k
end

RAGCOM_CHARS = {
	--1
	{
		model="models/barney.mdl",
		name="Space Captain Spudz Mackenzie",
		desc="He is a certified idiot and founded Ragdoll Combat after being dishonorably discharged from the space navy.",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/spudz_face"])
			ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/spudz_body"])
		end,
		neg="vo/npc/Barney/ba_ohshit03.wav",
		pos="vo/npc/Barney/ba_laugh01.wav"
	},
	--2
	{
		model="models/mossman.mdl",
		name="Ellen Pow",
		desc="After her great success with Reddit, Pow decided to take up martial arts!",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetSubMaterial(5,RAGCOM_MATS["ragcom/pow_face"])
			ragdoll:SetSubMaterial(0,RAGCOM_MATS["ragcom/pow_body"])
			ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/pow_hair"])
		end,
		neg="vo/npc/female01/help01.wav",
		pos="vo/coast/odessa/female01/nlo_cheer01.wav"
	},
	--3
	{
		model="models/humans/group01/male_04.mdl",
		name="Shia LaBeouf",
		desc="I don't need an excuse to put Shia LaBeouf my damn gamemode. I have one. I just don't need it.",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/shia_face"])
			ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/shia_body"])
		end,
		neg="vo/coast/odessa/male01/nlo_cubdeath01.wav",
		pos="ragcom/shia_win.wav"
	},
	--4
	{
		model="models/player/skeleton.mdl",
		name="Skeleton John",
		desc="Spooky!",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetMaterial("models/debug/debugwhite")
			--ragdoll:SetColor(Color(255,100,100))
			ragdoll:SetColor(Color(math.random(255),math.random(255),math.random(255)))
		end,
		neg="npc/zombie/zombie_die1.wav",
		pos="npc/fast_zombie/fz_scream1.wav"
	},
	--5
	{
		model="models/barney.mdl",
		name="Mecha Postal",
		desc="New and improved. Now with more ass.",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/postal_face"])
			ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/postal_body"])
			
			--[[if SERVER then
				local e1 = ents.Create("prop_dynamic")
				e1:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
				e1:Spawn()
				local p = ragdoll:GetBonePosition(6)
				e1:SetPos(p+Vector(6.5,-4.5,0))
				e1:SetAngles(Angle(0,0,90))
				e1:SetModelScale(.08,0)
				e1:FollowBone(ragdoll,6)
				e1:DrawShadow(false)
				ragdoll:DeleteOnRemove(e1)

				local e2 = ents.Create("prop_dynamic")
				e2:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
				e2:Spawn()
				local p = ragdoll:GetBonePosition(6)
				e2:SetPos(p+Vector(6.5,-4.5,3))
				e2:SetAngles(Angle(0,0,90))
				e2:SetModelScale(.08,0)
				e2:FollowBone(ragdoll,6)
				e2:DrawShadow(false)
				ragdoll:DeleteOnRemove(e1)
			end]]
		end,
		neg="ragcom/postal_fall.wav",
		pos="ragcom/postal_win.wav"
	},
	--6
	{
		model="models/alyx.mdl",
		name="Melon Senpai",
		desc="Fruit Punch!",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetMaterial("models/debug/debugwhite")
			-- 10,255,50
			ragdoll:SetColor(Color(math.random(255),math.random(255),math.random(255)))
			
			if SERVER then
				local m = ents.Create("prop_dynamic")
				m:SetModel("models/props_junk/watermelon01.mdl")
				m:Spawn()
				local p = ragdoll:GetBonePosition(ragdoll:LookupBone('ValveBiped.Bip01_Head1'))
				m:SetPos(p+Vector(5,0,-5))
				m:FollowBone(ragdoll,6)
				ragdoll:DeleteOnRemove(m)
			end

		end,
		neg="garrysmod/balloon_pop_cute.wav",
		pos="ambient/alarms/razortrain_horn1.wav"
	},
	--7
	{
		model="models/odessa.mdl",
		name="Mr. Crittersworth",
		desc="Must try appealing to the judges. I don't even know at this point.",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetSubMaterial(0,RAGCOM_MATS["ragcom/critter_face"])
			ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/critter_body"])
			ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/critter_hat"])
		end,
		neg="npc/crow/alert2.wav",
		pos="npc/dog/dog_playfull1.wav"
	},
	--8
	{
		model="models/combine_soldier.mdl",
		name="Officer SassyPants",
		desc="Here come the black CIA helicopters!",
		quote=[[
		
		]],
		setup=function(ragdoll)
			--ragdoll:SetSubMaterial(0,RAGCOM_MATS["ragcom/critter_face"])
			--ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/critter_body"])
			--ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/critter_hat"])
		end,
		neg="vo/npc/male01/pain01.wav",
		pos="vo/npc/male01/moan05.wav"
	},
	
	--9
	{
		model="models/player/charple.mdl",
		name="Fire Marshall Bill",
		desc="Is it hot in here, or is it just me?",
		quote=[[
		
		]],
		setup=function(ragdoll)
			--ragdoll:SetSubMaterial(0,RAGCOM_MATS["ragcom/critter_face"])
			--ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/critter_body"])
			--ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/critter_hat"])
		end,
		neg="player/pl_burnpain1.wav",
		pos="player/pl_burnpain1.wav"
	},
	--10
	{
		model="models/player/corpse1.mdl",
		name="Deady McDeadFace",
		desc="Why?",
		quote=[[
		
		]],
		setup=function(ragdoll)
			--ragdoll:SetSubMaterial(0,RAGCOM_MATS["ragcom/critter_face"])
			--ragdoll:SetSubMaterial(4,RAGCOM_MATS["ragcom/critter_body"])
			--ragdoll:SetSubMaterial(2,RAGCOM_MATS["ragcom/critter_hat"])
		end,
		neg="npc/zombie/zombie_pain2.wav",
		pos="player/pl_burnpain1.wav"
	},
	--11
	{

		model="models/player/kleiner.mdl",
		name="Crab Person",
		desc="Why?",
		quote=[[
		
		]],
		setup=function(ragdoll)
			ragdoll:SetMaterial("models/debug/debugwhite")
			ragdoll:SetColor(Color(255,100,50))
			
			if SERVER then
				ragdoll:ManipulateBoneScale(11, Vector(2,2,2) )
				ragdoll:ManipulateBoneScale(16, Vector(2,2,2) )
			end
		end,
		neg="npc/headcrab_poison/ph_pain1.wav",
		pos="npc/headcrab_poison/ph_scream1.wav"
	}
}
