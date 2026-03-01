-- Millennium Spellbook

local s,id=GetID()
function s.initial_effect(c)

	-- ①: Set "Millennium Stone" and immediately activate it
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	-- ②: Add 1 "Millennium" Counter to "Millennium Stone" once per turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.ctcon)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	-- ③: Shuffle 2 cards from your hand into the Deck, then draw 2 cards
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+2)
	e3:SetCost(s.cost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.activate)
	c:RegisterEffect(e3)

	--④: If a Ritual Monster(s) you control would be destroyed by battle or card effect, you can banish this card from your GY instead.
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

-- ①: Target "Millennium Stone" from Deck to set
function s.setfilter(c)
	return c:IsCode(130000537) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local tc=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if tc and Duel.SSet(tp,tc)>0 and tc:IsLocation(LOCATION_SZONE) then
		Duel.BreakEffect()
		-- Immediately activate the set "Millennium Stone"
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- ②: Check for "Millennium Stone" is face-up and if it can add 1 counter
function s.ctfilter(c)
	return c:IsCode(130000537) and c:IsFaceup() and c:IsCanAddCounter(0x90,1)
end

-- ②: Check if "Millennium Stone" is face-up and can accept a counter
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

-- ②: Add 1 'Millennium' Counters to "Millennium Stone" (max7)
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ctfilter,tp,LOCATION_ONFIELD,0,nil)
	local tc=g:GetFirst()
	while tc do
		tc:AddCounter(0x90,1)
		tc=g:GetNext()
	end
end

-- ③: Return 2 "Millennium" or "Diabound" cards from your Graveyard to the Deck 
function s.cfilter(c)
	return c:IsSetCard(0xfad,0xfa1) and c:IsAbleToDeckAsCost()
end

-- Cost for Effect ③: Pay 300 LP
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,300) end  -- Check if LP cost can be paid
	Duel.PayLPCost(tp,300)  -- Pay 300 LP
end

-- Target: Shuffle up to 2 cards from your hand into the Deck
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2)
		and Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetTargetPlayer(tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND) 
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

-- Operation: Shuffle up to 2 cards into the Deck, then draw 2 cards
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(p,Card.IsAbleToDeck,p,LOCATION_HAND,0,1,2,nil)
	if #g>0 then
		-- Shuffle the selected cards into the Deck
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		Duel.ShuffleDeck(p)
		Duel.BreakEffect()
		Duel.Draw(p,#g,REASON_EFFECT)
	end
end


-- Filter to identify Ritual Monsters that are targeted for destruction (by battle or card effect)
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) and c:IsType(TYPE_RITUAL)
		and c:IsReason(REASON_EFFECT+REASON_BATTLE) and not c:IsReason(REASON_REPLACE)
end

-- Target function to determine if replacement can be applied
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

--Operation: Banish this card from the GY as a replacement for the destruction of the Ritual Monster
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end