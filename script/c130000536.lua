-- Millennium Necklace

local s,id=GetID()
function s.initial_effect(c)

	-- ①: Remove 1 "Millennium" counter from your field; negate the activation, and if you do, destroy that card.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.discon)
	e1:SetCost(s.discost)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	
	-- ②: If sent to GY by "Millennium Stone", rearrange top 3 cards and force a draw
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	-- ③:  ③: If you control "Diabound" monster, Set this card from GY, banish when it leaves the field 
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- ①: Negate activation of Spell/Trap and destroy it
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and Duel.IsChainNegatable(ev)
end

-- Cost: Remove 1 "Millennium" counter from the field
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,0,0x90,1,REASON_COST) end
	Duel.RemoveCounter(tp,1,0,0x90,1,REASON_COST)
end

-- Target the activating Spell/Trap card
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- Negate the activation and destroy the card
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- ②: Check if this card was sent to the GY by "Millennium Stone"
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return re and re:IsActivated() and rc:IsCode(130000537) -- ID of "Millennium Stone"
end

-- Look at top 3 cards of opponent's Deck and force a draw, applying additional effects
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=3 end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetDecktopGroup(1-tp,3)
	if #g>0 then
		Duel.ConfirmCards(tp,g)
		Duel.SortDecktop(tp,1-tp,#g)
		Duel.BreakEffect()
		-- Opponent draws 1 card
		local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
		Duel.Draw(1-tp,1,REASON_EFFECT)
		
		if tc:IsType(TYPE_EFFECT) then
			-- If an Effect Monster is drawn, banish 2 cards from their hand
			local hg=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
			if #hg>=2 then
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_REMOVE)
				local sg=hg:Select(1-tp,2,2,nil)
				Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
			end
		elseif tc:IsType(TYPE_SPELL+TYPE_TRAP) then
			-- If a Spell/Trap is drawn, return 2 face-up cards to the Deck
			local fg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
			if #fg>=2 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
				local rg=fg:Select(tp,2,2,nil)
				Duel.SendtoDeck(rg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			end
		end
	end
end

-- ③: Check if you control a "Diabound" monster
function s.setfilter(c)
	return c:IsSetCard(0xfa1) and c:IsFaceup()
end

-- Condition: You control a "Diabound" monster
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

-- Target: Set this card from GY
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

-- Set this card from GY, banish it when it leaves the field
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SSet(tp,c)~=0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1)
	end
end