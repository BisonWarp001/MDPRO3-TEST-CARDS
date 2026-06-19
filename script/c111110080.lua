-- Calling of the Dark Gods
local s,id=GetID()
function s.initial_effect(c)
	-- Lista de códigos de los Dioses Malvados (Originales y Custom)
	aux.AddCodeList(c,62180201,21208154,57793869)

	-- (1) Add 1 Level 10 DARK Fiend that cannot be Special Summoned
	-- and 1 Spell/Trap that mentions the Wicked Gods, then discard 1 card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- (2) GY: Banish; Tribute Summon 1 monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
end

-- Spell/Trap that mentions Wicked Gods
function s.thfilter1(c)
	return (aux.IsCodeListed(c,62180201)
		or aux.IsCodeListed(c,21208154)
		or aux.IsCodeListed(c,57793869))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsAbleToHand()
end

-- Level 10 DARK Fiend that cannot be Special Summoned
function s.thfilter2(c)
	return c:IsCode(62180201,21208154,57793869)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Seleccionar Spell/Trap
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter1),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g1==0 then return end

	-- Seleccionar monstruo Fiend
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g2=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g2==0 then return end

	g1:Merge(g2)

	if Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g1)
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		Duel.DiscardHand(tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD,nil)
	end
end

-- Tribute Summon filter
function s.sumfilter(c)
	return c:IsSummonable(true,nil)
end

function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end