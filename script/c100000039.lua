local s,id=GetID()
s.listed_series={0x42,0x4b}
s.listed_names={100000040,93483212}

function s.initial_effect(c)

	aux.AddCodeList(c,100000040)
	aux.AddCodeList(c,93483212)

	-------------------------------------------------
	-- ① Set Valhalla (HOPT #1)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_DECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,100000039)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-------------------------------------------------
	-- ② Reducir Nivel (HOPT #2)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_LVCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,100000039+100)
	e2:SetCondition(s.lvcon)
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- ③ Negar efecto que invoque (HOPT #3)
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetCountLimit(1,100000039+200)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- ① Set Valhalla
-------------------------------------------------

function s.setfilter(c)
	return c:IsCode(100000040)
		and c:IsType(TYPE_FIELD)
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SSet(tp,tc)
	end
end

-------------------------------------------------
-- ② Reducir Nivel
-------------------------------------------------

function s.lvcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsLevelAbove(2)
	end
	Duel.SetOperationInfo(0,CATEGORY_LVCHANGE,c,1,0,0)
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFacedown() or not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) then return end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- ③ Negación
-------------------------------------------------

function s.odinfilter(c)
	return c:IsFaceup() and c:IsCode(93483212)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end
	if not Duel.IsExistingMatchingCard(s.odinfilter,tp,LOCATION_MZONE,0,1,nil) then return false end
	if not re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) then return false end
	if not Duel.IsChainDisablable(ev) then return false end
	return re:IsHasCategory(CATEGORY_SPECIAL_SUMMON)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	
	Duel.Remove(c,POS_FACEUP,REASON_COST)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetLabelObject(c)
	e1:SetOperation(s.retop)
	Duel.RegisterEffect(e1,tp)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c and c:IsLocation(LOCATION_REMOVED) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end