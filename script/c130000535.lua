-- Millennium Key

local s,id=GetID()

function s.initial_effect(c)

	aux.AddCodeList(c,130000500)  -- Reference to "Diabound Kernel LV 4"
	
	-- Effect ①: Banish a monster with 2000 or more ATK
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effect ②: Skip opponent's next Battle Phase if sent to GY by "Millennium Stone"
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.stonecon)
	e2:SetTarget(s.stonetarget)
	e2:SetOperation(s.stoneop)
	c:RegisterEffect(e2)
end

-- Filter for monsters with 2000 or more ATK that can be banished
function s.rmfilter(c)
	return c:IsAttackAbove(2000) and c:IsFaceup() and c:IsAbleToRemove()
end

-- Check if the player controls "Diabound" or a card related to "Millennium Stone"
function s.cfilter(c)
	return (c:IsSetCard(0xfa1) or (aux.IsCodeListed(c,130000500) and c:IsLocation(LOCATION_MZONE)))
		and c:IsFaceup()
end

-- Target selection for banishing a monster
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.rmfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
	local ct=Duel.GetMatchingGroupCount(s.cfilter,tp,LOCATION_ONFIELD,0,nil)
	e:SetLabel(ct)
end

-- Check for "Millennium Rod" and Set if conditions are met
function s.stfilter(c)
	return c:IsCode(130000534) and c:IsSSetable()
end

-- Activate banish effect, return the banished monster at the End Phase, and possibly Set "Millennium Rod"
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsType(TYPE_MONSTER) and Duel.Remove(tc,0,REASON_EFFECT+REASON_TEMPORARY)~=0 then
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetReset(RESET_PHASE+PHASE_END,2)
		e1:SetLabelObject(tc)
		e1:SetCountLimit(1)
		e1:SetCondition(s.retcon)
		e1:SetOperation(s.retop)
		e1:SetLabel(Duel.GetTurnCount())
		Duel.RegisterEffect(e1,tp)

		-- Check if conditions are met to Set "Millennium Rod"
		local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.stfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
		if e:GetLabel()>0 and #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sc=g:Select(tp,1,1,nil)
			Duel.SSet(tp,sc)
		end
	end
end

-- Return the banished monster at the End Phase
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return Duel.GetTurnCount()~=e:GetLabel() and tc:GetFlagEffect(id)~=0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc and Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_REMOVED,0,1,tc) then
		Duel.ReturnToField(tc)
	end
end

-- Condition for Effect ②: Sent to GY by "Millennium Stone"
function s.stonecon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsCode(130000537)
end

-- **Condition for LP Difference**: Player's Life Points must be 2000 lower than opponent's to trigger skipping of Battle Phase
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)+2000<=Duel.GetLP(1-tp)
end

-- Target selection for skipping opponent's next Battle Phase
function s.stonetarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(1-tp,EFFECT_SKIP_BP) end
end

-- Skip opponent's Battle Phase if LP condition is met
function s.stoneop(e,tp,eg,ep,ev,re,r,rp)
	if s.condition(e,tp,eg,ep,ev,re,r,rp) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_SKIP_BP)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(0,1)
		if Duel.GetTurnPlayer()~=tp and (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE) then
			e1:SetLabel(Duel.GetTurnCount())
			e1:SetCondition(s.skipcon)
			e1:SetReset(RESET_PHASE+PHASE_BATTLE+RESET_OPPO_TURN,2)
		else
			e1:SetReset(RESET_PHASE+PHASE_BATTLE+RESET_OPPO_TURN,1)
		end
		Duel.RegisterEffect(e1,tp)
	end
end

-- Condition to prevent skipping the Battle Phase in the same turn
function s.skipcon(e)
	return Duel.GetTurnCount()~=e:GetLabel()
end
