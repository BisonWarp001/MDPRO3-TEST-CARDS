--The Domain of Fear
local s,id=GetID()

function s.initial_effect(c)
	-- Code list
	aux.AddCodeList(c,62180201)

	-------------------------------------------------
	-- ① Activate: Add + Extra Tribute Summon
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY: Attack all monsters
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search "The Wicked Dreadroot"
-------------------------------------------------
function s.thfilter(c)
	return c:IsCode(62180201) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,aux.NecroValleyFilter(s.thfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g==0 then return end
	if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,g)

	-------------------------------------------------
	-- Extra Tribute Summon (once this turn)
	-------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(function(_,c)
		return c:IsTributeSummonable()
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	Duel.RegisterEffect(e1,tp)
end

-------------------------------------------------
-- GY Effect: Can attack all monsters
-------------------------------------------------
function s.dreadfilter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.dreadfilter,tp,LOCATION_MZONE,0,1,nil)
	end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(
		tp,s.dreadfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
end