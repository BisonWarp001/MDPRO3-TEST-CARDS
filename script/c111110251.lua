-- Progenitor God - The Winged Dragon of Ra
local s,id=GetID()
s.listed_series={0x3f2}
function s.initial_effect(c)
	-- Siempre se trata como "The Winged Dragon of Ra"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(10000010)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Invocación Normal (3 tributos, no Set)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetCondition(s.ttcon)
	e1:SetOperation(s.ttop)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e1)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SET_PROC)
	e2:SetCondition(s.setcon)
	c:RegisterEffect(e2)

	-- Invocación no puede ser negada
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e3)

	-------------------------------------------------
	-- Bloqueo de activación e Inmunidad
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetOperation(s.sumsuc)
	c:RegisterEffect(e4)

	-------------------------------------------------
	-- (1) LP → ATK/DEF (opcional)
	-------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,4))
	e5:SetCategory(CATEGORY_ATKCHANGE)
	e5:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e5:SetCode(EVENT_SUMMON_SUCCESS)
	e5:SetCountLimit(1)
	e5:SetCost(s.atkcost)
	e5:SetOperation(s.atkop)
	c:RegisterEffect(e5)

	-------------------------------------------------
	-- (2) Quick Effect: destruir monstruos
	-------------------------------------------------
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e6:SetCost(s.descost)
	e6:SetTarget(s.destg)
	e6:SetOperation(s.desop)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (3) Revivir en Standby con 4000/4000
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_DESTROYED)
	e7:SetCountLimit(1)
	e7:SetCondition(s.spcon)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- (4) End Phase: enviar al GY si fue Special
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,3))
	e8:SetCategory(CATEGORY_TOGRAVE)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetCode(EVENT_PHASE+PHASE_END)
	e8:SetCondition(s.tgcon)
	e8:SetTarget(s.tgtg)
	e8:SetOperation(s.tgop)
	c:RegisterEffect(e8)
end

-------------------------------------------------
-- Invocación
-------------------------------------------------
function s.ttcon(e,c,minc)
	if c==nil then return true end
	return minc<=3 and Duel.CheckTribute(c,3)
end
function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,3,3)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end

-------------------------------------------------
-- Bloqueo + Inmunidad
-------------------------------------------------
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.SetChainLimitTillChainEnd(s.chainlm(c))
	if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
function s.efilter(e,te)
	return te:IsActivated() and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.chainlm(c)
	return function(e,rp,tp)
		return e:GetHandler()==c
	end
end

-------------------------------------------------
-- (1) LP → ATK/DEF
-------------------------------------------------
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local lp=Duel.GetLP(tp)
	if chk==0 then return lp>100 end
	local val=lp-100
	e:SetLabel(val)
	Duel.PayLPCost(tp,val)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local val=e:GetLabel()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		c:RegisterEffect(e2)
	end
end

-------------------------------------------------
-- (2) Destruir
-------------------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_MZONE,1,nil,TYPE_MONSTER) end
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
	if #g>0 then Duel.Destroy(g,REASON_EFFECT) end
end

-------------------------------------------------
-- (3) Revivir
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&(REASON_BATTLE+REASON_EFFECT))~=0
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	e1:SetCondition(function(e,tp)
		return Duel.GetTurnPlayer()==tp
	end)
	e1:SetOperation(s.spop2)
	e1:SetLabelObject(c)
	e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN)
	Duel.RegisterEffect(e1,tp)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c and c:IsLocation(LOCATION_GRAVE) then
		if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(4000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
			c:RegisterEffect(e2)
		end
	end
end

-------------------------------------------------
-- (4) End Phase enviar
-------------------------------------------------
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end