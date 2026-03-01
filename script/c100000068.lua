--The Curse of Destruction
local s,id=GetID()

function s.initial_effect(c)

	--------------------------------
	-- Mention The Wicked Eraser
	--------------------------------
	aux.AddCodeList(c,57793869)

	--------------------------------
	-- Activate: Add + Normal Summon
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--------------------------------
	-- GY Effect: Banish to apply burn
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.gycon)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search + Normal Summon
-------------------------------------------------

function s.thfilter(c)
	return c:IsCode(57793869) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local tc=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.thfilter),
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,1,1,nil
	):GetFirst()
	if not tc then return end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,tc)
		if tc:IsSummonable(true,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Summon(tp,tc,true,nil)
		end
	end
end

-------------------------------------------------
-- GY Effect: Damage Setup
-------------------------------------------------

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		function(c) 
			return c:IsFaceup() and c:IsCode(57793869) 
		end,
		tp,LOCATION_MZONE,0,1,nil
	)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 1) Detect when The Wicked Eraser is destroyed
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCondition(s.markcon)
	e1:SetOperation(s.markop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- 2) Detect when its effect destroys cards
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetCondition(s.damcon)
	e2:SetOperation(s.damop)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- Mark that Wicked Eraser was destroyed
function s.markcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsCode(57793869)
			and c:IsReason(REASON_DESTROY)
			and c:IsPreviousLocation(LOCATION_MZONE)
	end,1,nil)
end

function s.markop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end

-- Check if its effect destroyed cards AFTER being destroyed
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)==0 then return false end
	if not re then return false end
	return re:GetHandler():IsCode(57793869)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetOperatedGroup()
	if not g or not re then return end

	local ct=g:FilterCount(function(c)
		return c:IsReason(REASON_EFFECT)
			and c:IsReason(REASON_DESTROY)
			and c:GetReasonEffect()
			and c:GetReasonEffect():GetHandler():IsCode(57793869)
	end,nil)

	if ct>0 then
		Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
	end
end