--Avatar Judgment
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,21208154)

	-- ① Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ② GY Protection
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(aux.bfgcost)
	e2:SetCondition(s.protcon)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Control The Wicked Avatar
-------------------------------------------------
function s.avatarfilter(c)
	return c:IsFaceup() and c:IsCode(21208154)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil)
end

-------------------------------------------------
-- Activation
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local avatar=Duel.GetFirstMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,nil)
	if not avatar then return end

	local atk=avatar:GetAttack()

	local g=Duel.GetMatchingGroup(function(tc)
		return tc:IsFaceup() and tc:GetAttack()<atk
	end,tp,0,LOCATION_MZONE,nil)

	if #g==0 then return end

	-- Apply negation + mark
	for tc in aux.Next(g) do
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end

	-- End Phase destruction
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetCountLimit(1)
	e3:SetOperation(s.desop)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

-------------------------------------------------
-- Destroy flagged monsters in End Phase
-------------------------------------------------
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(tc)
		return tc:IsFaceup()
			and tc:IsControler(1-tp)
			and tc:GetFlagEffect(id)>0
	end,tp,0,LOCATION_MZONE,nil)

	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-------------------------------------------------
-- GY Protection
-------------------------------------------------
function s.protcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(_,tc)
		return tc:IsCode(21208154)
	end)
	e1:SetValue(function(e,re)
		return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end