--True Horror
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,62180201)

	-- Activate (register End Battle Phase burn)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.actop)
	e1:SetCountLimit(1,id) -- HOPT efecto 1
	c:RegisterEffect(e1)

	-- GY effect (protection)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1) -- HOPT efecto 2
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.prottg)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
end

-- Control Dreadroot
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Register delayed burn
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e1:SetCountLimit(1)
	e1:SetOperation(s.burnop)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
end

-- End of Battle Phase burn
function s.burnop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local dmg=0
	for tc in aux.Next(g) do
		if tc:GetAttackedCount()==0 then
			dmg=dmg+tc:GetAttack()
		end
	end
	if dmg>0 then
		Duel.Damage(1-tp,dmg,REASON_EFFECT)
	end
end

-- GY target
function s.protfilter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

function s.prottg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingTarget(s.protfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.SelectTarget(tp,s.protfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

-- Apply protection
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(function(e,te)
		return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
			and te:IsActiveType(TYPE_MONSTER)
	end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
end