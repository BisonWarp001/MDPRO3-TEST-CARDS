--Authority of the Sky God
local s,id=GetID()

function s.initial_effect(c)
	-- Code list (Slifer)
	aux.AddCodeList(c,10000020)

	-------------------------------------------------
	-- ① Activate: Add Slifer + Extra Tribute Summon (OATH)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY: Banish; draw until you have 6 cards (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.gycon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search Slifer the Sky Dragon
-------------------------------------------------
function s.thfilter(c)
	return c:IsCode(10000020) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Add Slifer
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,aux.NecroValleyFilter(s.thfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g==0 then return end

	Duel.SendtoHand(g,nil,REASON_EFFECT)
	Duel.ConfirmCards(1-tp,g)

	-------------------------------------------------
	-- Extra Tribute Summon (shared with Ancient Chant)
	-------------------------------------------------
	if Duel.GetFlagEffect(tp,78665705)~=0 then return end
	if not (Duel.IsPlayerCanSummon(tp) and Duel.IsPlayerCanAdditionalSummon(tp)) then return end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsLevelAbove,5))
	e1:SetValue(0x1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_EXTRA_SET_COUNT)
	Duel.RegisterEffect(e2,tp)

	-- Flag global (Ancient Chant compatible)
	Duel.RegisterFlagEffect(tp,78665705,RESET_PHASE+PHASE_END,0,1)
end

-------------------------------------------------
-- Draw until you have 6 cards
-------------------------------------------------
function s.sliferfilter(c)
	return c:IsFaceup() and c:IsCode(10000020)
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.sliferfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=6-Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	if chk==0 then
		return ct>0 and Duel.IsPlayerCanDraw(tp,ct)
	end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=6-Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	if ct<=0 then return end
	Duel.Draw(tp,ct,REASON_EFFECT)
end