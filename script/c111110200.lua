--The Wicked Dreadroot (Custom)
local s,id=GetID() --111110200

function s.initial_effect(c)
	-- (REGLA) Nombre siempre The Wicked Dreadroot
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(62180201) -- ID original de Dreadroot
	c:RegisterEffect(e0)
	
		--Summon with 3 Tributes
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)
	e1:SetCondition(s.ttcon)
	e1:SetOperation(s.ttop)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_LIMIT_SET_PROC)
	c:RegisterEffect(e2)

	--Cannot Special Summon
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_SPSUMMON_CONDITION)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e3)

	--Halve ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_SET_ATTACK_FINAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e4:SetTarget(s.tg)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)

	--Halve DEF
	local e5=e4:Clone()
	e5:SetCode(EFFECT_SET_DEFENSE_FINAL)
	e5:SetValue(s.defval)
	c:RegisterEffect(e5)
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	return minc<=3 and Duel.CheckTribute(c,3)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,3,3)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON|REASON_MATERIAL)
end

function s.tg(e,c)
	return c~=e:GetHandler()
end

function s.skipavatar(e,c)
	if not c:IsCode(111110201) then return false end
	local dread=e:GetHandler()
	return c:GetFieldID()>dread:GetFieldID()
end

function s.atkval(e,c)
	if s.skipavatar(e,c) then
		return c:GetAttack()
	end
	return math.ceil(c:GetAttack()/2)
end

function s.defval(e,c)
	if s.skipavatar(e,c) then
		return c:GetDefense()
	end
	return math.ceil(c:GetDefense()/2)
end