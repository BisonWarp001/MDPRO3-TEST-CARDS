--The Wicked Avatar (Custom)
local s,id=GetID() --111110201

function s.initial_effect(c)
	-- (REGLA) Nombre siempre The Wicked Dreadroot
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(21208154) -- ID original de Avatar
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

	--ATK/DEF = highest ATK +100
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_SET_ATTACK_FINAL)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.adval)
	c:RegisterEffect(e4)

	local e5=e4:Clone()
	e5:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e5)
	--aclimit
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_SUMMON_SUCCESS)
	e6:SetOperation(s.regop)
	c:RegisterEffect(e6)
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

function s.filter(c)
	-- Usamos "id" para referirnos a tu carta custom y evitar bucles
	return c:IsFaceup() and not c:IsCode(id) and not c:IsHasEffect(id)
end

function s.adval(e,c)
	local g=Duel.GetMatchingGroup(s.filter,0,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g==0 then
		return 100
	else
		local _,val=g:GetMaxGroup(Card.GetAttack)
		-- Si el ATK más alto es 0, el resultado es 100
		return (val > 0 and val or 0)+100
	end
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,2)
	Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
