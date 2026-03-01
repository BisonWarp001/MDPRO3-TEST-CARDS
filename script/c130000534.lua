-- Millennium Rod

local s,id=GetID()
function s.initial_effect(c)

	-- Activate and target 1 Effect Monster to disable it and prevent attacks
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CONTINUOUS_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	
	-- Disable the effects of the targeted monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_TARGET)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetRange(LOCATION_SZONE)
	c:RegisterEffect(e2)
	
	-- Prevent the targeted monster from attacking
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e3)
	
	-- Destroy this card when the targeted monster is destroyed
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCondition(s.descon)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- GY effect: Destroy a Special Summoned monster and banish top 2 cards
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e5:SetCondition(s.stonecon)
	e5:SetTarget(s.stonetarget)
	e5:SetOperation(s.activate)
	c:RegisterEffect(e5)

end

-- Filter to target a face-up Effect Monster
function s.filter(c)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end

-- Targeting for the first effect
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

-- Apply disabling and prevent attack to the targeted monster
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		c:SetCardTarget(tc)
	end
end

-- Condition to destroy this card when the targeted monster is destroyed
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetFirstCardTarget()
	return tc and eg:IsContains(tc) and tc:IsReason(REASON_DESTROY)
end

-- Destroy this card
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end

-- GY effect condition: Sent to the GY by "Millennium Stone"
function s.stonecon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsCode(130000537)
end

-- Target 1 Special Summoned monster your opponent controls and banish top 2 cards from their Deck
function s.stonetarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsSummonType(SUMMON_TYPE_SPECIAL) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsSummonType,tp,0,LOCATION_MZONE,1,nil,SUMMON_TYPE_SPECIAL)
		and Duel.GetDecktopGroup(1-tp,2):FilterCount(Card.IsAbleToRemove,nil)==2 end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsSummonType,tp,0,LOCATION_MZONE,1,1,nil,SUMMON_TYPE_SPECIAL)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,1-tp,LOCATION_DECK)
end

-- Execute the GY effect: Destroy the targeted monster and banish the top 2 cards
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
		local g=Duel.GetDecktopGroup(1-tp,2)
		if #g>0 then
			Duel.BreakEffect()
			Duel.DisableShuffleCheck()
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end
	end
end
