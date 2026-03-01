-- Divine Comeback
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,10000000,10000010,10000020)

	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Single Effect (Choose 1)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- COST
-------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

-------------------------------------------------
-- BASE FILTER
-------------------------------------------------
function s.godfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and not c:IsCode(id)
		and (
			aux.IsCodeListed(c,10000000)
			or aux.IsCodeListed(c,10000010)
			or aux.IsCodeListed(c,10000020)
		)
end

function s.setfilter(c)
	return s.godfilter(c) and c:IsSSetable()
end

function s.shufflefilter(c)
	return s.godfilter(c) and c:IsAbleToDeck()
end

-------------------------------------------------
-- TARGET (FIXED)
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.shufflefilter,tp,LOCATION_GRAVE,0,1,nil)

	if chk==0 then return b1 or b2 end

	local op
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=0
	else
		op=1
	end
	e:SetLabel(op)

	-- Declarar categoría según elección
	if op==0 then
		e:SetCategory(CATEGORY_SET)
		Duel.SetOperationInfo(0,CATEGORY_SET,nil,1,tp,LOCATION_DECK)
	else
		e:SetCategory(CATEGORY_TODECK)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
	end
end

-------------------------------------------------
-- OPERATION
-------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	-- Set from Deck
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			local tc=g:GetFirst()
			if Duel.SSet(tp,tc)>0 then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				local e2=e1:Clone()
				e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
				tc:RegisterEffect(e2)
			end
		end

	-- Shuffle from GY
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.shufflefilter,tp,LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end