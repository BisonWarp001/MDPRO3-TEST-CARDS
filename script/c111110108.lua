--Shadow Torment - Jeroid the Dark Warper
local s,id=GetID()
function s.initial_effect(c)

	--ATK/DEF loss on summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.statstg)
	e1:SetOperation(s.statsop)
	c:RegisterEffect(e1)

	local e1x=e1:Clone()
	e1x:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1x)

	--GY ATK reduction
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.atkcost)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

end

--TARGET
function s.statstg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsFaceup() and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

--OPERATION
function s.statsop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	--ATK reduction
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(-800)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	tc:RegisterEffect(e1)

	--DEF reduction
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	e2:SetValue(-800)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	tc:RegisterEffect(e2)

	--Check result AFTER reduction
	if tc:IsAttack(0) then
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			Duel.Damage(1-tp,1000,REASON_EFFECT)
		end
	end

end

--GY cost
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

--Count Shadow Torment monsters
function s.gyfilter(c)
	return c:IsSetCard(0x406) and c:IsMonster()
end

--GY effect
function s.atkop(e,tp,eg,ep,ev,re,r,rp)

	local ct=Duel.GetMatchingGroupCount(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	if ct==0 then return end

	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end

	local val=ct*400

	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end

end