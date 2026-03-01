-- Millennium Stone

local s,id=GetID()
function s.initial_effect(c)

	-- Enable Counter Permit (allows the card to gain 'Millennium' Counters)
	c:EnableCounterPermit(0x90)
	c:SetCounterLimit(0x90,7)

	-- Activate the card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ①: Add Millennium Counters during each End Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	-- ②: Special Summon "Zorc Necrophades" when 7 counters are placed
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- ③: Add Millennium Counter if a 'Millennium' card is sent to the GY from hand/field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.millenniumSentToGY)
	e3:SetOperation(s.counterop)
	c:RegisterEffect(e3)

	-- ④: While this card is in your GY: Target 3 "Diabound" cards in your GY, Draw 2
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCondition(s.indcon)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	aux.RegisterMergedDelayedEvent(c,EVENT_CUSTOM+id,g)
end

-- ①: Filter to identify "Millennium" Spell/Trap Cards for sending to GY
function s.ctfilter(c)
	return c:IsSetCard(0xfad) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToGrave()
end

-- ①: Target for placing "Millennium" Counters (send 1 'Millennium' Spell/Trap from hand, field, or deck to GY)
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_DECK,0,1,nil)
		and e:GetHandler():GetCounter(0x90)<7 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_DECK)
end

-- ①: Operation to send the card to GY and place a "Millennium" Counter
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetCounter(0x90)>=7 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.ctfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		c:AddCounter(0x90,1)
	end
end

-- ②: Condition to check if the card has 7 'Millennium' Counters
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetCounter(0x90)>=7
end

-- ②: Target for Special Summoning "Zorc Necrophades" from hand, Deck, or GY
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

-- ②: Filter for Special Summoning "Zorc Necrophades"
function s.spfilter(c,e,tp)
	return c:IsCode(130000510) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

-- ②: Operation to send "Millennium Stone" to the GY and Special Summon "Zorc Necrophades"
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoGrave(c,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			local tc=g:GetFirst()
			Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
			tc:CompleteProcedure() 
		end
	end
end

-- ③: Millennium card sent from hand/field to the GY, place a counter
function s.millenniumSentToGY(e,tp,eg,ep,ev,re,r,rp)
   return eg:IsExists(s.millenniumfilter,1,nil,tp)
end

-- Filter to check if a "Millennium" card is sent from hand or field to GY
function s.millenniumfilter(c,tp)
   return c:IsSetCard(0xfad) and c:IsControler(tp) 
			and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_ONFIELD))
end

-- ③: Operation to add a 'Millennium' Counter
function s.counterop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():AddCounter(0x90,1)
end

-- ④: Indestructible condition if there are 3 counters on the card
function s.indcon(e)
	return e:GetHandler():GetCounter(0x90)==3
end