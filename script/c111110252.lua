-- Progenitor God - Slifer the Sky Dragon
local s,id=GetID()
s.listed_series={0x3f2}
function s.initial_effect(c)
	-- Siempre se trata como "Slifer the Sky Dragon"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(10000020)
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
	-- ATK/DEF por cartas en mano
	-------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.adval)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (1) Reducción de 2000 ATK y destrucción
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCode(EVENT_SUMMON_SUCCESS)
	e7:SetTarget(s.atktg)
	e7:SetOperation(s.atkop)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e8)

	-------------------------------------------------
	-- (2) Quick Effect: Discard -> Negate equal/lower ATK
	-------------------------------------------------
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,2))
	e9:SetCategory(CATEGORY_DISABLE)
	e9:SetType(EFFECT_TYPE_QUICK_O)
	e9:SetCode(EVENT_FREE_CHAIN)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1)
	e9:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e9:SetCost(s.negcost)
	e9:SetTarget(s.negtg)
	e9:SetOperation(s.negop)
	c:RegisterEffect(e9)

	-------------------------------------------------
	-- (3) End Phase: Send to GY if Special Summoned
	-------------------------------------------------
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,3))
	e10:SetCategory(CATEGORY_TOGRAVE)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1)
	e10:SetCode(EVENT_PHASE+PHASE_END)
	e10:SetCondition(s.tgcon)
	e10:SetTarget(s.tgtg)
	e10:SetOperation(s.tgop)
	c:RegisterEffect(e10)
end

-- Auxiliares Invocación
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

-- Inmunidad y Bloqueo
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

-- ATK/DEF dinámico
function s.adval(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_HAND,0)*1000
end

-- Lógica (1) Slifer Original
function s.atkfilter(c,tp)
	return c:IsControler(tp) and c:IsPosition(POS_FACEUP_ATTACK)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.atkfilter,1,nil,1-tp) end
	local g=eg:Filter(s.atkfilter,nil,1-tp)
	Duel.SetTargetCard(g)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToChain,nil):Filter(Card.IsFaceup,nil)
	local dg=Group.CreateGroup()
	local c=e:GetHandler()
	local tc=g:GetFirst()
	while tc do
		local preatk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-2000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		if preatk~=0 and tc:IsAttack(0) then dg:AddCard(tc) end
		tc=g:GetNext()
	end
	if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
end

-- Lógica (2) Negación masiva
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.negfilter(c,atk)
	return c:IsFaceup() and c:GetAttack()<=atk and not c:IsDisabled()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_MZONE,1,nil,c:GetAttack()) end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local g=Duel.GetMatchingGroup(s.negfilter,tp,0,LOCATION_MZONE,nil,c:GetAttack())
	local tc=g:GetFirst()
	while tc do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		tc=g:GetNext()
	end
end

-- Lógica (3) Auto-envío
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end
