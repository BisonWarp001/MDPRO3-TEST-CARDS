-- Aura of Intimidation
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,62180201)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------
-- Condition
--------------------------------------------------

function s.confilter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------
-- Position Change
--------------------------------------------------

function s.posfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.posfilter,tp,0,LOCATION_MZONE,1,nil)
	end

	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
end

--------------------------------------------------
-- Attack Restriction
--------------------------------------------------

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	if not tc or not tc:IsControler(tp) then return end

	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c~=tc end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------------------------
-- Activate
--------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end

	if Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)==0 then return end

	local og=Duel.GetOperatedGroup()
	local fg=og:Filter(Card.IsPosition,nil,POS_FACEDOWN_DEFENSE)

	local tc=fg:GetFirst()
	while tc do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e1)
		tc=fg:GetNext()
	end

	local ph=Duel.GetCurrentPhase()

	if Duel.GetTurnPlayer()~=tp then return end
	if ph~=PHASE_MAIN1 and ph~=PHASE_MAIN2 then return end

	if not Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,1)) then
		return
	end

	Duel.BreakEffect()

	-- All your monsters can attack directly
	local mg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,0,nil)

	local mc=mg:GetFirst()
	while mc do
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DIRECT_ATTACK)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		mc:RegisterEffect(e2)
		mc=mg:GetNext()
	end

	-- Only 1 monster can attack this turn
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD|EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetOperation(s.regop)
	e3:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e3,tp)
end