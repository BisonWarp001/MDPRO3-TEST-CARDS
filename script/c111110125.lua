-- Shadow Torment Pact
local s,id=GetID()
function s.initial_effect(c)
	-- ① Activate: Add 1 "Shadow Torment" monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg1)
	e1:SetOperation(s.thop1)
	c:RegisterEffect(e1)

	-- ② GY trigger: add this card if opponent tributes a monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_RELEASE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon2)
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)
end

-- ① Filter: "Shadow Torment" monster
function s.thfilter1(c)
	return c:IsSetCard(0x406) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ② Condition: opponent tributed a monster
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsDamageStep() then return false end
	return eg:IsExists(s.relfilter,1,nil,tp)
end

function s.relfilter(c,tp)
	return c:IsPreviousControler(1-tp)
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return e:GetHandler():IsAbleToHand()
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,LOCATION_GRAVE)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.SendtoHand(c,nil,REASON_EFFECT)~=0 then
		-- Banish it when it leaves the field
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1)
	end
end