-- Nordic Horror - Ouroboros Break
local s,id=GetID()

s.listed_series={0x4b}

function s.initial_effect(c)
	aux.AddCodeList(c,64203620) -- Jormungardr
	
	-------------------------------------------------
	-- ① Take control (HOPT en condición)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- Destroy + Search when monster leaves
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCondition(s.descon)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Must control an Aesir + HOPT
-------------------------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		function(c) return c:IsFaceup() and c:IsSetCard(0x4b) end,
		tp,LOCATION_MZONE,0,1,nil
	)
end

-------------------------------------------------
-- Target opponent Effect Monster
-------------------------------------------------
function s.filter(c,tp)
	return c:IsFaceup()
		and c:IsType(TYPE_EFFECT)
		and c:IsControler(1-tp)
		and c:IsAbleToChangeControler()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.filter,tp,0,LOCATION_MZONE,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_MZONE,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

-------------------------------------------------
-- Take control
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end

	if Duel.GetControl(tc,tp) then	

		-- Cannot activate effects while controlled
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_TRIGGER)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		c:SetCardTarget(tc)
	end
end

-------------------------------------------------
-- If controlled monster leaves
-------------------------------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetFirstCardTarget()
	return tc and eg:IsContains(tc)
end

function s.thfilter(c)
	return c:IsCode(64203620) and c:IsAbleToHand()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	if Duel.Destroy(c,REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end