--The Altar of the Ultimate Gods
local s,id=GetID()
s.listed_series={0x3e8}

function s.initial_effect(c)

	-------------------------------------------------
	-- Activate
	-------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- (1) Cannot be destroyed twice per turn
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetCountLimit(2)
	e1:SetValue(s.indct)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- (2) Search "Ultimate God" card (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- (3) Tribute → draw (3 times per turn)
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_RELEASE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(3,id+100)
	e3:SetOperation(s.drawop)
	c:RegisterEffect(e3)

end

-------------------------------------------------
-- (1) destruction protection
-------------------------------------------------
function s.indct(e,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

-------------------------------------------------
-- (2) Search
-------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x3e8) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-------------------------------------------------
-- (3) Tribute → draw
-------------------------------------------------
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp)
end

function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.cfilter,1,nil,tp) then return end
	Duel.Draw(tp,1,REASON_EFFECT)
end