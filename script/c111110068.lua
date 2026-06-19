-- Curse of Destruction
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,57793869)

	-- ACTIVACIÓN: Quick-Play Spell + This card's activation cannot be negated.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(TIMING_STANDBY_PHASE+TIMINGS_CHECK_MONSTER+TIMING_MAIN_END,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- (2) Efecto en Cementerio: Quick Effect de desterrar para aplicar daño de quemadura
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_STANDBY_PHASE+TIMINGS_CHECK_MONSTER+TIMING_MAIN_END,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Effect (1)
-------------------------------------------------

function s.tgfilter(c)
	return c:IsFaceup() and c:IsCode(57793869) and c:GetFlagEffect(id)==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.tgfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))

	local ec=tc

	local e1=Effect.CreateEffect(tc)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1)
	e1:SetCondition(function(e)
		return Duel.GetTurnPlayer()~=e:GetHandlerPlayer()
	end)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		if ec and ec:IsFaceup() then
			Duel.Destroy(ec,REASON_EFFECT)
		end
	end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

-------------------------------------------------
-- Lógica del Efecto (2)
-------------------------------------------------

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAIN_SOLVED)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	Duel.RegisterEffect(e1,tp)
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	return rc:IsCode(57793869) and re:IsHasCategory(CATEGORY_DESTROY) and rc:IsPreviousControler(tp)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetOperatedGroup()
	if not g or #g==0 then return end

	local ct=g:FilterCount(function(c)
		return c:IsReason(REASON_DESTROY)
	end,nil)

	if ct>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
	end
end
