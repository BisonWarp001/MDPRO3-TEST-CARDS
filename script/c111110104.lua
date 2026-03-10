--Shadow Torment - Newdoria of Despair
local s,id=GetID()
function s.initial_effect(c)

	--If destroyed: destroy 1 opponent card, then burn
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--Banish from GY to search
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

end

-------------------------------------------------
-- Destroy condition
-------------------------------------------------

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return (r&(REASON_BATTLE|REASON_EFFECT))~=0
end

-------------------------------------------------
-- Destroy target
-------------------------------------------------

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsOnField() and chkc:IsControler(1-tp)
	end

	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)

end

-------------------------------------------------
-- Destroy operation
-------------------------------------------------

function s.desop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)~=0 then

		local ct=Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_GRAVE,0,nil,0x406)

		if ct>0 then
			Duel.Damage(1-tp,ct*300,REASON_EFFECT)
		end

	end
end

-------------------------------------------------
-- Banish cost
-------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return e:GetHandler():IsAbleToRemoveAsCost()
	end

	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)

end

-------------------------------------------------
-- Search filter
-------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x406)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

-------------------------------------------------
-- Search target
-------------------------------------------------

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end

	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)

end

-------------------------------------------------
-- Search operation
-------------------------------------------------

function s.thop(e,tp,eg,ep,ev,re,r,rp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end

end