-- Millennium Eye

local s,id=GetID()
function s.initial_effect(c)

	aux.AddCodeList(c,130000537)
	-- Effect ①: Destroy monsters and lock zones if "Millennium Stone" is on the field
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effect ②: If sent to GY by "Millennium Stone", shuffle 1 random card from opponent's hand into Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.stonetarget)
	e2:SetCondition(s.stonecon)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- Effect ①: "Millennium Stone" is on the field
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsEnvironment(130000537)
end

-- Filter for DARK monsters with original Level 4 or higher
function s.filter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK) and c:GetOriginalLevel()>=4
end

-- Effect ①: Target opponent's monsters for destruction
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	local ct=Duel.GetMatchingGroupCount(s.filter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return ct>0 and Duel.IsExistingTarget(nil,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,g:GetCount(),0,0)
end

-- Effect ①: Destroy targeted monsters and lock their zones
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if g:GetCount()==0 then return end
	if Duel.Destroy(g,REASON_EFFECT)==0 then return end  -- Destroy monsters
	local val=0
	local og=Duel.GetOperatedGroup()  -- Get destroyed monsters
	local tc=og:GetFirst()
	while tc do
		val=val|aux.SequenceToGlobal(tc:GetPreviousControler(),LOCATION_MZONE,tc:GetPreviousSequence())
		tc=og:GetNext()
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetValue(val)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	Duel.RegisterEffect(e1,tp)
end

--  Effect ②: Sent to GY by "Millennium Stone"
function s.stonecon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:IsActivated() and re:GetHandler():IsCode(130000537)
end

-- Check if opponent has cards in hand
function s.stonetarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
end

-- Randomly select 1 card from opponent's hand and shuffle it into the Deck
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if g:GetCount()==0 then return end
	local sg=g:RandomSelect(tp,1)
	Duel.ConfirmCards(tp,sg)
	if Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then  -- Shuffle the card into the Deck
		Duel.ShuffleHand(1-tp)
	end
end