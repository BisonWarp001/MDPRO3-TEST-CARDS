-- Shadow Torment - Lekunga of Dark Corruption
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x406),1)

	-- Token summon effect (up to twice per turn)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(2,id)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)

	-- Add banished Shadow Torment monster to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_RELEASE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1000)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Token target check
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

-- Token operation
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_GRAVE,0,1,2,nil)
	if #g==0 then return end

	local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	if ct==0 then return end

	-- Elegir en qué campo invocar
	local p=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	local player=(p==0) and tp or 1-tp

	local ft=Duel.GetLocationCount(player,LOCATION_MZONE)
	if ft<=0 then return end
	if ft<ct then ct=ft end

	for i=1,ct do
		local token=Duel.CreateToken(tp,111110129)
		Duel.SpecialSummonStep(token,0,tp,player,false,false,POS_FACEUP)

		-- Restricciones del token
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UNRELEASABLE_SUM)
		e1:SetValue(function(e,c) return not c:IsSetCard(0x406) end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
		token:RegisterEffect(e2)

		local e3=e1:Clone()
		e3:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
		token:RegisterEffect(e3)

		local e4=e1:Clone()
		e4:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
		token:RegisterEffect(e4)

		local e5=e1:Clone()
		e5:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		token:RegisterEffect(e5)
	end

	Duel.SpecialSummonComplete()
end

-- Trigger condition: opponent tributes a monster
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsPreviousControler(1-tp) end,1,nil)
end

-- Target for adding banished Shadow Torment monster
function s.thfilter(c)
	return c:IsSetCard(0x406) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
end

-- Operation: add to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end