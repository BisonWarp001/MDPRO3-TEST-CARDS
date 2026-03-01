-- Zorc Necrophades

local s,id=GetID()
function s.initial_effect(c)

	-- Enable Ritual Summon with "Great Magus, Priest of Darkness" or "Millennium Stone"
	aux.AddRitualProcGreaterCode(c,130000537)

	-- ① Can attack all monsters once each
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- ② Opponent discards a card or negates their monster effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.handes)
	c:RegisterEffect(e2)

	-- ④ Cannot be targeted or destroyed by opponent's card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)

	-- ④ Indestructible 
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(aux.indoval)
	c:RegisterEffect(e4)

	-- ⑤ Special Summon from GY if opponent controls an Extra Deck monster
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.spcon)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)

	-- ⑥ Limit each player to control 1 non-DARK monster while "Kul Elna, the Cursed Ruins" is on the field
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(130000510)
	e6:SetRange(LOCATION_MZONE)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetTargetRange(1,1)
	e6:SetCondition(s.condition)
	c:RegisterEffect(e6)

	-- Summon limits (Normal, Special, and Flip Summons)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCode(EFFECT_LIMIT_SPECIAL_SUMMON_POSITION)
	e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e7:SetCondition(s.condition)
	e7:SetTargetRange(1,1)
	e7:SetTarget(s.sumlimit)
	c:RegisterEffect(e7)

	local e8=e7:Clone()
	e8:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e8)

	local e9=e7:Clone()
	e9:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e9)

	-- Adjust monster count due to effect of "Kul Elna, the Cursed Ruins"
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		ge1:SetCode(EVENT_ADJUST)
		ge1:SetOperation(s.adjustop)
		Duel.RegisterEffect(ge1,0)
	end
end

c130000510[0]=0
c130000510[1]=0

-- ② Opponent discards a card or effect is negated
function s.handes(e,tp,eg,ep,ev,re,r,rp)
	local loc,id=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION,CHAININFO_CHAIN_ID)
	if ep==tp or loc~=LOCATION_MZONE or id==c130000510[0] or not re:IsActiveType(TYPE_MONSTER) then return end
	c130000510[0]=id
	if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,0)) then
		Duel.DiscardHand(1-tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD,nil)
		Duel.BreakEffect()
	else Duel.NegateEffect(ev) end
end

-- ⑤ Special Summon from GY if opponent controls Extra Deck monster
function s.cfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_RITUAL+TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,0,LOCATION_MZONE,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1)
	end
	Duel.SpecialSummonComplete()
end

-- ⑥ Limit each player to control 1 non-DARK monster
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsEnvironment(130000526)  -- Condition for the field being active
end

function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
	if sumpos and bit.band(sumpos,POS_FACEDOWN)>0 then return false end
	return c:IsNonAttribute(ATTRIBUTE_DARK) and c130000510[targetp or sump]==1
end

-- Adjust monsters sent to the Graveyard based on "Kul Elna" limit
function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerAffectedByEffect(0,130000510) then
		c130000510[0]=0
		c130000510[1]=0
		return
	end
	local phase=Duel.GetCurrentPhase()
	if (phase==PHASE_DAMAGE and not Duel.IsDamageCalculated()) or phase==PHASE_DAMAGE_CAL then return end
	local g1=Duel.GetMatchingGroup(s.wtfilter,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.wtfilter,tp,0,LOCATION_MZONE,nil)
	local c=e:GetHandler()
	if g1:GetCount()==0 then c130000510[tp]=0
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g1:SelectSubGroup(tp,s.tgselect,false,#g1-1,#g1-1,g1)
		if sg then
			g1:Sub(g1-sg)
		else
			g1:Sub(g1)
		end
		c130000510[tp]=1
	end
	if g2:GetCount()==0 then c130000510[1-tp]=0
	else
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
		local sg=g2:SelectSubGroup(1-tp,s.tgselect,false,#g2-1,#g2-1,g2)
		if sg then
			g2:Sub(g2-sg)
		else
			g2:Sub(g2)
		end
		c130000510[1-tp]=1
	end
	g1:Merge(g2)
	if g1:GetCount()>0 then
		Duel.SendtoGrave(g1,REASON_RULE)
		Duel.Readjust()
	end
end
