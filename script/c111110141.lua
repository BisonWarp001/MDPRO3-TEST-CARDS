--Wrath of the Ultimate Gods
local s,id=GetID()
s.listed_series={0x3e8}

function s.initial_effect(c)
	c:EnableReviveLimit()

	-------------------------------------------------
	-- Fusion materials (exactly 3)
	-------------------------------------------------
	aux.AddFusionProcFunRep(c,s.matfilter,3,true)

	-------------------------------------------------
	-- Contact Fusion
	-------------------------------------------------
	aux.AddContactFusionProcedure(c,
		function(c)
			-- Solo monstruos "Ultimate God"
			return c:IsSetCard(0x3e8) and c:IsType(TYPE_MONSTER)
		end,
		LOCATION_MZONE,0,
		function(g)
			Duel.SendtoGrave(g,REASON_MATERIAL+REASON_COST)
		end,
		nil,
		aux.FCheckAdditional=function(tp,sg,fc)
			-- Verifica que sean exactamente 3 materiales
			return #sg==3
		end
	)
	
	-------------------------------------------------
	-- Cannot negate Special Summon
	-------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Chain lock
	-------------------------------------------------
	local e0b=Effect.CreateEffect(c)
	e0b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e0b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e0b:SetOperation(s.sumsuc)
	c:RegisterEffect(e0b)

	-------------------------------------------------
	-- (1) Banish field + GY + burn
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1)
	e1:SetCondition(s.burncon)
	e1:SetTarget(s.burntg)
	e1:SetOperation(s.burnop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ATK/DEF = sum of materials
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_ATTACK_FINAL)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_SET_DEFENSE_FINAL)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)

	-------------------------------------------------
	-- Unaffected
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.immfilter)
	c:RegisterEffect(e4)

	-------------------------------------------------
	-- (2) Negate (ONCE PER CHAIN REAL)
	-------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,EFFECT_COUNT_CODE_CHAIN) -- 🔥 CLAVE
	e5:SetCondition(s.negcon)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
	
	-------------------------------------------------
	-- Destroy → banish
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_BATTLE_DESTROY_REDIRECT)
	e7:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e7)

	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e8:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e8:SetCondition(s.rdcon)
	e8:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e8)

	-------------------------------------------------
	-- 🔥 STORE MATERIAL STATS (FIX REAL)
	-------------------------------------------------
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	e9:SetOperation(s.statop)
	c:RegisterEffect(e9)
end

-------------------------------------------------
-- Filters
-------------------------------------------------
function s.matfilter(c)
	return c:IsSetCard(0x3e8) and c:IsType(TYPE_MONSTER)
end

function s.cfilter(c)
	return c:IsSetCard(0x3e8)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
end

-------------------------------------------------
-- 🔥 CALCULAR STATS CORRECTAMENTE
-------------------------------------------------
function s.statop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	if not mg or #mg==0 then return end

	local atk,def=0,0

	for tc in aux.Next(mg) do
		local a=tc:GetPreviousAttackOnField()
		local d=tc:GetPreviousDefenseOnField()

		atk=atk+math.max(a,0)
		def=def+math.max(d,0)
	end

	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,atk)
	c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD,0,1,def)
end

function s.atkval(e,c)
	return c:GetFlagEffectLabel(id) or 0
end

function s.defval(e,c)
	return c:GetFlagEffectLabel(id+1) or 0
end

-------------------------------------------------
-- Chain lock
-------------------------------------------------
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

-------------------------------------------------
-- Burn
-------------------------------------------------
function s.burncon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonLocation(LOCATION_EXTRA)
end

function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.burntg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*500)
end

function s.burnop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,nil)
	local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	if ct>0 then
		Duel.Damage(1-tp,ct*500,REASON_EFFECT)
	end
end

-------------------------------------------------
-- Immunity
-------------------------------------------------
function s.immfilter(e,te)
	return te:GetOwner()~=e:GetHandler()
end

-------------------------------------------------
-- Negate
-------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp 
		and Duel.IsChainNegatable(ev)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end

-------------------------------------------------
-- Redirect
-------------------------------------------------
function s.rdcon(e,tp,eg,ep,ev,re,r,rp)
	return r&REASON_DESTROY~=0
end