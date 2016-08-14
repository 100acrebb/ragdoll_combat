AddCSLuaFile()

ENT.Type   = "anim"
local energy_fall = 5
ENT.MaxEnergy = 60


function ENT:SetupDataTables()
	self:NetworkVar("Entity",0,"Ragdoll")
	self:NetworkVar("Entity",1,"Controller")

	self:NetworkVar("Int",0,"Energy")
	self:NetworkVar("Int",1,"Weakness")
	self:NetworkVar("Int",2,"Char")
end

local SIDE_LEFT = true
local SIDE_RIGHT = false

local step_time = .33
local stride_length = 60 //60
local stride_height = 25

local function find_bone(ent,name)
	local bone = ent:LookupBone(name)
	if bone then
		return ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bone))
	end
end

local function GetPhysObjName(ent, name)
	
	--if (!ent.mapPhysObj) then ent.mapPhysObj = {} end
	
	if (ent.mapPhysObj[name]) then
		return ent.mapPhysObj[name]
		--print("a")
	else
		local physobj = nil
		local mappedname = name
		if (ent.RagdollItem and ent.RagdollItem.bonemap and ent.RagdollItem.bonemap[name]) then
			mappedname = ent.RagdollItem.bonemap[name]
		end
		
		local boneid = ent:LookupBone(mappedname)
		local physboneid = nil
		if (boneid) then
			physboneid = ent:TranslateBoneToPhysBone(boneid)
			if (physboneid) then
				physobj = ent:GetPhysicsObjectNum(physboneid)
			end
		end
		
		ent.mapPhysObj[name] = physobj
		--print (name, " boneid = ", boneid, " physboneid = ", physboneid, " physobj = ", physobj )
		return physobj
	end
	
	
	return nil
end

function ENT:Initialize()		
	if SERVER then
		local ply = self:GetController()
		
		
		self:SetModel("models/props_c17/computer01_keyboard.mdl")
		local ragdoll = ents.Create("prop_ragdoll")
		ragdoll.mapPhysObj = {}
		

		if ply.RagdollItem != nil then
			ragdoll:SetModel(ply.RagdollItem.Model)
			ragdoll.RagdollItem = ply.RagdollItem
		else
			ragdoll:SetModel(RAGCOM_CHARS[ply.char].model) -- legacy, really just for bot support
		end
		
		ragdoll:SetPos(self:GetPos())
		ragdoll:Spawn()
		self:SetRagdoll(ragdoll)
		
		

		ragdoll:SetFlexWeight(0,1)
		ragdoll:SetFlexWeight(1,1)
		
		ragdoll:SetOwner(self:GetController())
		self:DeleteOnRemove(ragdoll)

		-- figure out how to get client side setup over to PS
		if ply:IsBot() or ply.RagdollItem.RCOriginal then   
			RAGCOM_CHARS[self:GetChar()].setup(ragdoll)
		end

		--for i=1,100 do
		--	print(i,ragdoll:GetBoneName(i),ragdoll:TranslateBoneToPhysBone(i), ragdoll:LookupBone( ragdoll:GetBoneName(i) ))
		--end
	

		--[[for i=26,55 do
			if (i-26)%15>11 then //Thumbs
				ragdoll:ManipulateBoneAngles(i,Angle(0,30,0))
			else
				ragdoll:ManipulateBoneAngles(i,Angle(0,-30,0))
			end
		end]]
 


		self.type_sound = CreateSound(self,"ambient/machines/keyboard_fast1_1second.wav")

		self.lean = Vector(0,0,0)

		self.steps = {}
		self.step_wait = true

		self.do_limp = false
		self.limp_timer = 0
		self.invuln_timer = 0

		self.punch_l = 0
		self.punch_r = 0
		self.blocking = false

		self.duck = false
		
		self.next_kicker = 0
        self.next_butter = 0

		self.next_jump = CurTime()
		self.next_valid_hit = CurTime()

		self:SetEnergy(self.MaxEnergy)
		self:SetWeakness(0)

		local ply = self:GetController()
		self.vang=ply:EyeAngles()
		self.vang.p = self.vang.p - 20
		self.yaw = Angle(0,self.vang.y,0)


		ply.controller = self
		
		self:StartMotionController()
		self:AddToMotionController(ragdoll:GetPhysicsObject())

		self:SetParent(ragdoll)
		self:SetLocalPos(Vector())


		self:DrawShadow(false)

		
		--[[if ragdoll:GetPhysicsObject() then
			ragdoll:GetPhysicsObject():SetMass(11)
			print("mass ", ragdoll:GetPhysicsObject():GetMass())
		end]]
		for i=1, ragdoll:GetPhysicsObjectCount() do
			ragdoll:GetPhysicsObjectNum(i-1):AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
			
			--[[if (i == 1) then
				ragdoll:GetPhysicsObjectNum(i-1):SetMass(11)
			elseif (i == 2) then
				ragdoll:GetPhysicsObjectNum(i-1):SetMass(22)
			else
				ragdoll:GetPhysicsObjectNum(i-1):SetMass(6)
			end
			print (ragdoll:GetPhysicsObjectNum(i-1):GetMass())]]
		end
		

		--[[self.body_set = { -- our damageable physobjs (head and body)
			GetPhysObjName(ragdoll, 'ValveBiped.Bip01_Spine1'),--   ragdoll:GetPhysicsObjectNum(0),
			GetPhysObjName(ragdoll, 'ValveBiped.Bip01_Neck1'),--ragdoll:GetPhysicsObjectNum(1),
			GetPhysObjName(ragdoll, 'ValveBiped.Bip01_Head1') --ragdoll:GetPhysicsObjectNum(10)
		}]]
		
		
		self.body_set = { -- our damageable physobjs (head and body)
			find_bone(ragdoll,"ValveBiped.Bip01_Pelvis"),
			find_bone(ragdoll,"ValveBiped.Bip01_Spine2"),
			find_bone(ragdoll,"ValveBiped.Bip01_Head1")
		}
		
		
		self.foot_l = find_bone(ragdoll,"ValveBiped.Bip01_L_Foot") or ragdoll:GetPhysicsObject()
		self.foot_r = find_bone(ragdoll,"ValveBiped.Bip01_R_Foot") or ragdoll:GetPhysicsObject()

		self.fist_l = find_bone(ragdoll,"ValveBiped.Bip01_L_Hand") or ragdoll:GetPhysicsObject()
		self.fist_r = find_bone(ragdoll,"ValveBiped.Bip01_R_Hand") or ragdoll:GetPhysicsObject()

		self.thigh_l = find_bone(ragdoll,"ValveBiped.Bip01_L_Thigh") or ragdoll:GetPhysicsObject()
		self.thigh_r = find_bone(ragdoll,"ValveBiped.Bip01_R_Thigh") or ragdoll:GetPhysicsObject()

		self.head = find_bone(ragdoll,"ValveBiped.Bip01_Head1") or ragdoll:GetPhysicsObject()

		ragdoll:AddCallback("PhysicsCollide",function(ragdoll,data) self:RagdollCollide(ragdoll,data) end)

		//base steps
		local control = Vector()

		self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
		self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
	else
		//I would fix this gud but I am running out of time FAST
		//timer.Simple(.1,function()
			//if not IsValid(self) then return end
			//local ragdoll = self:GetRagdoll()
			
			self.head_bone = self:GetRagdoll():LookupBone("ValveBiped.Bip01_Head1")
			
			//print(">>",self:GetChar())

			if self:GetController()==LocalPlayer() then
				LocalPlayerController = self
			end
		//end)
	end
end

local shadow_data = {
	secondstoarrive = .0001,
	maxangular = 1000,
	maxangulardamp = 10000,
	maxspeed = 1000,
	maxspeeddamp = 10000,
	dampfactor = .8,
	teleportdistance = 1000
}

local function doControl(phys,pos,ang)

	shadow_data.pos = pos
	shadow_data.angle = ang

	if !ang then
		shadow_data.maxangular = 0
		phys:ComputeShadowControl(shadow_data)
		shadow_data.maxangular = 1000
	else
		phys:ComputeShadowControl(shadow_data)
	end
end

function ENT:PhysicsSimulate(phys_body,dt)
	if not IsValid(self:GetController()) then
		self:Remove()
		return
	end
	
	local ply = self:GetController()
	self:GetController():SetPos(self:GetPos())

	--debugoverlay.Cross(self:GetController():GetPos(), 10, 1,Color(255,255,0), false)

	local ragdoll = self:GetRagdoll()
	local phys_footl = self.foot_l --GetPhysObjName(ragdoll, 'ValveBiped.Bip01_L_Foot')
	local phys_footr = self.foot_r --GetPhysObjName(ragdoll, 'ValveBiped.Bip01_R_Foot')
	
	

	--local vang = ply:EyeAngles()
	--vang.p = 0
	--self.yaw = LerpAngle(.1,self.yaw,vang)
	
	self.vang = ply:EyeAngles()
	self.vang.p = self.vang.p - 20
	self.yaw = Angle(0,self.vang.y,0)
	
	if self.invuln_timer > 0 then
		self.invuln_timer = self.invuln_timer-dt
	end

	if self.limp_timer > 0 then
		self.limp_timer = self.limp_timer-dt

		if self.limp_timer > 0 then
			return
		else
			
			local control = Vector()

			self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
			self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)

			if self.do_limp then
				self.limp_timer=.5
				self.do_limp=false
				return //failed to stand up... notify user somehow?
			end

			self.ctrl_jump=nil
			self.ctrl_attack_1=nil
			self.ctrl_attack_2=nil
			
			self.ctrl_kick=nil
            self.ctrl_butt=nil
			
			self.last_attacker = nil

			self.next_jump = CurTime()+2
			self.next_kick = CurTime()+5

			self.invuln_timer = .5

		end
	end

	local phys_head = self.head -- GetPhysObjName(ragdoll, 'ValveBiped.Bip01_Head1') --ragdoll:GetPhysicsObjectNum(10)

	if self.ctrl_jump and CurTime()>self.next_jump and self.lean:Length()>0 then
		self:EmitSound("npc/headcrab_poison/ph_jump1.wav")
		self.limp_timer = 2
		local vel = Vector(0,0,900)+self.lean*400
		phys_body:SetVelocity(vel)
		phys_head:SetVelocity(vel)
		return
	end

	shadow_data.deltatime = dt

	if ply:IsTyping() != self.type_sound:IsPlaying() then
		if ply:IsTyping() then
			self.type_sound:Play()
		else
			self.type_sound:Stop()
		end
	end

	local phys_fistl = self.fist_l -- GetPhysObjName(ragdoll, 'ValveBiped.Bip01_L_Hand') -- ragdoll:GetPhysicsObjectNum(5)
	local phys_fistr = self.fist_r -- GetPhysObjName(ragdoll, 'ValveBiped.Bip01_R_Hand') -- ragdoll:GetPhysicsObjectNum(7)

	if ply:IsTyping() then
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10+math.sin(CurTime()*50)*10)+self.yaw:Forward()*15+self.yaw:Right()*-5)
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10-math.sin(CurTime()*50)*10)+self.yaw:Forward()*15+self.yaw:Right()*5)
	elseif self.won then
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,40+math.sin(CurTime()*10)*20)+self.yaw:Forward()*10+self.yaw:Right()*-5)
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,40+math.sin(CurTime()*10)*20)+self.yaw:Forward()*10+self.yaw:Right()*5)
	elseif self.punch_l>0 then
		self.punch_l=self.punch_l-dt
		if self.punch_l>.3 then
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,80)+self.yaw:Forward()*150)
		else
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
		end
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
	elseif self.punch_r>0 then
		self.punch_r=self.punch_r-dt
		if self.punch_r>.3 then
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,80)+self.yaw:Forward()*150)
		else
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
		end
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
	
	elseif self.next_kicker>0 then
		self.next_kicker=self.next_kicker-dt
		if self.next_kicker>0.35 then
			doControl(phys_footr,phys_body:GetPos()+Vector(0,0,80)+self.yaw:Forward()*150)
			doControl(phys_footr,phys_body:GetAngles():Forward()) -- kick
        else
			doControl(phys_footr,phys_body:GetPos()+Vector(0,0,10))	
        end
        doControl(phys_footr,phys_body:GetPos()+Vector(0,0,0))			
		
    elseif self.next_butter>0 then
		self.next_butter=self.next_butter-dt
		if self.next_butter>.35 then
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,30))
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,30))
			doControl(phys_head,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*150)
			doControl(phys_head,phys_body:GetAngles():Forward())	
        end
	
	else
		self.blocking = ply:KeyDown(IN_RELOAD)
		if self.blocking then
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,30)+self.yaw:Forward()*10+self.yaw:Right()*-3)
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,30)+self.yaw:Forward()*10+self.yaw:Right()*3)
		else
			if self.ctrl_attack_1 then
				self.punch_l=.5
				self:EmitSound("npc/vort/claw_swing1.wav")
			elseif self.ctrl_attack_2 then
				self.punch_r=.5
				self:EmitSound("npc/vort/claw_swing2.wav")
			elseif self.ctrl_kick then
				self.next_kicker=.5
				self:EmitSound("npc/zombie/claw_miss1.wav")			             
			elseif self.ctrl_butt then
				self.next_butter=.5
				self:EmitSound("npc/fast_zombie/claw_miss1.wav")			   
			end              


			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
		end
	end

	self.ctrl_jump=nil
	self.ctrl_attack_1=nil
	self.ctrl_attack_2=nil
	self.ctrl_kick=nil
    self.ctrl_butt=nil
	
	local foot_base = (phys_footl:GetPos()+phys_footr:GetPos())/2  //self.step_alt //(self.step_alt+self.step_goal)*.5
	foot_base.z = math.min(phys_footl:GetPos().z,phys_footr:GetPos().z)
	foot_base = foot_base + self.lean

	self.duck = ply:KeyDown(IN_DUCK)


	foot_base = foot_base + (self.duck and Vector(0,0,10) or Vector(0,0,30))

	doControl(phys_body,foot_base,self.yaw+Angle(0,90,90))
	doControl(phys_head,foot_base+Vector(0,0,40),self.yaw+Angle(-90,90,0))  //mid vec component = -n to lean fwd


	if self.step_wait then
		self:StepPoll()
	end


	self:StepThink(SIDE_LEFT,dt)
	self:StepThink(SIDE_RIGHT,dt)


	--ragdoll:GetPhysicsObjectNum(8)
	--GetPhysObjName(ragdoll, 'ValveBiped.Bip01_R_Thigh'):AddAngleVelocity( Vector(0,0,-50) )
	--ragdoll:GetPhysicsObjectNum(11)
	--GetPhysObjName(ragdoll, 'ValveBiped.Bip01_L_Thigh'):AddAngleVelocity( Vector(0,0,-50) )
	
	self.thigh_l:AddAngleVelocity( Vector(0,0,-50) )
	self.thigh_r:AddAngleVelocity( Vector(0,0,-50) )
end

if SERVER then
	function ENT:Think()
		--local ragdoll = self:GetRagdoll()
		self:GetRagdoll():PhysWake()
	end
end

function ENT:GetFootBone(side)
	--local ragdoll = self:GetRagdoll()
	--return side and GetPhysObjName(ragdoll, 'ValveBiped.Bip01_R_Foot') or GetPhysObjName(ragdoll, 'ValveBiped.Bip01_L_Foot')
	
	return side and self.foot_r or self.foot_l
end

function ENT:StepStart(side,goal,time,height)
	local bone = self:GetFootBone(side)

	self.steps[side] = {
		t= 0,
		start= bone:GetPos(),
		goal= goal,
		time = time,
		height = height
	}

	self.step_wait = false
end

function ENT:StepThink(side,dt)
	local step = self.steps[side]
	if not step then return end

	local bone = self:GetFootBone(side)

	if step.t<1 then
		step.t = step.t + dt/step.time

		local foot_pos = LerpVector(step.t,step.start,step.goal)
		foot_pos.z = foot_pos.z + math.sin(step.t*math.pi)*step.height
		doControl(bone,foot_pos)

		if step.t>=1 then
			self.step_wait = true
			self:EmitSound("player/footsteps/wood"..math.random(1,4)..".wav")
		end
	else
		doControl(bone,step.goal)
	end
end

function ENT:StepPoll()
	local ply = self:GetController()
	
	local step_time_adj =  (ply.SpeedFactor and ply.SpeedFactor > 0) and step_time / ply.SpeedFactor or step_time
	
	if self.do_limp then
		self.do_limp = false
		self.limp_timer = 3

		if (ply.RagdollItem and ply.RagdollItem.neg) then
			self:EmitSound(ply.RagdollItem.neg)
		else
			self:EmitSound("vo/npc/male01/pain01.wav")
		end
		self:TryTakeEnergy(energy_fall)
		return
	end

	local fwd = 0
	if ply:KeyDown(IN_FORWARD) then
		fwd = 1
	elseif ply:KeyDown(IN_BACK) then
		fwd = -1
	end

	local left = 0
	if ply:KeyDown(IN_MOVELEFT) then
		left = 1
	elseif ply:KeyDown(IN_MOVERIGHT) then
		left = -1
	end

	local control = Vector(left,-fwd,0)
	control:Normalize()

	if self.duck or self.blocking then control=control*.5 end

	self.lean = control*10
	//self.lean.x = self.lean.x*.5
	self.lean:Rotate(self.yaw+Angle(0,90,0))

	local pos_l = self.steps[SIDE_LEFT] and self.steps[SIDE_LEFT].goal or self:GetFootBone(SIDE_LEFT):GetPos()
	local pos_r = self.steps[SIDE_RIGHT] and self.steps[SIDE_RIGHT].goal or self:GetFootBone(SIDE_RIGHT):GetPos()

	pos_l = WorldToLocal(pos_l,Angle(0,0,0),self:GetPos(),self.yaw+Angle(0,90,0))
	pos_r = WorldToLocal(pos_r,Angle(0,0,0),self:GetPos(),self.yaw+Angle(0,90,0))

	if fwd==0 then
		local feet_close = (pos_r.x-pos_l.x)<0

		if left==0 then
			local feet_dist_sqr = pos_l:DistToSqr(pos_r)

			if feet_close or feet_dist_sqr>400 then
				self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
				self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
			end
		elseif feet_close then
			/*if left==0 then
				self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
				self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
			end*/

			self:StepStart(left<0,self:GetStepPos(left<0,control),step_time_adj,stride_height)
		else
			if left==0 then return end
			self:StepStart(left>0,self:GetStepPos(left>0,control),step_time_adj,stride_height)
		end
	else
		local front = pos_r.y-pos_l.y>0
		local leader
		if fwd>0 then
			leader = !front
		else
			leader = front
		end

		self:StepStart(leader,self:GetStepPos(leader,control),step_time_adj,stride_height)
	end
end

function ENT:GetStepPos(side,control)
	local ragdoll = self:GetRagdoll()

	local foot_offset = side and Vector(-5) or Vector(5)
	if control.y==0 and control.x!=0 then
		foot_offset.y = side and -5 or 5
	end

	foot_offset = foot_offset + control*stride_length

	foot_offset:Rotate(self.yaw+Angle(0,90,0))

	local base_pos = ragdoll:GetPhysicsObject():GetPos() + foot_offset
	
	local end_pos = base_pos+Vector(0,0,-80) // ~30 to ground, then another 50

	local tr = util.TraceLine{start = base_pos, endpos = end_pos, filter=ragdoll}

	if not tr.Hit or tr.StartSolid then
		self.do_limp = true
		--print("limp 1")
	end

	return tr.HitPos
end

function ENT:TryTakeEnergy(n)
	local current = self:GetEnergy()
	if n<current then
		self:SetEnergy(current-n)
		return true
	end
end

function ENT:ForceTakeEnergy(n)
	local current = self:GetEnergy()
	if n>=current then
		self:SetEnergy(self.MaxEnergy)
		self:SetWeakness(self:GetWeakness()+1)
		
		local ply = self:GetController()
		if (ply.RagdollItem and ply.RagdollItem.neg) then
			self:EmitSound(ply.RagdollItem.neg)
		else
			self:EmitSound("vo/npc/male01/pain01.wav")
		end
		
		self.limp_timer = 2
		return true
	else
		self:SetEnergy(current-n)
	end
end

-- note: self is the ragdoll :/
function ENT:RagdollCollide(ragdoll,data)

	local limp = self.limp_timer>0

	if self.invuln_timer<= 0 and data.Speed>50 and (not data.HitEntity:IsWorld() or limp) then
		local hurt = false
		for k,v in pairs(self.body_set) do
			if v == data.PhysObject then hurt=true break end
		end

		local dmg
		if limp and data.HitEntity:IsWorld() then
			dmg = 2
		elseif limp or self.blocking then
			dmg = 1
		elseif self.next_butter>0 then
			dmg = 1
		else
			dmg = 3
		end

		if hurt then
			if self.next_valid_hit<=CurTime() then
				self:EmitSound("physics/body/body_medium_impact_hard2.wav",75,50,.5)
				self.next_valid_hit=CurTime()+.5
			end
			if self:ForceTakeEnergy(dmg) then
				local punt_dir

				if not limp then
					punt_dir = data.TheirOldVelocity 
					
				else
					//punt_dir = -data.OurOldVelocity
					punt_dir = VectorRand()
					punt_dir.z = math.abs(punt_dir.z)
				end

				punt_dir:Normalize()
				local punt_power = 100+300*self:GetWeakness()
				local pp = punt_dir*punt_power
				for i=1, ragdoll:GetPhysicsObjectCount() do
					ragdoll:GetPhysicsObjectNum(i-1):SetVelocity(pp)
				end

				if IsValid(data.HitEntity) and not data.HitEntity:IsWorld() then
					self.last_attacker = data.HitEntity:GetOwner()
				end
			end
		end
	end

	
end

function ENT:WinTaunt()
	net.Start("ragcom_sound")
	
	local ply = self:GetController()
	if (ply.RagdollItem and ply.RagdollItem.pos) then
		net.WriteString(ply.RagdollItem.pos)
	else
		net.WriteString("vo/npc/male01/moan05.wav")
	end
	net.Broadcast()

	self.won=true
end

function ENT:Draw()

end