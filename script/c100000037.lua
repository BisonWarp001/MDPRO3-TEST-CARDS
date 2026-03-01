-- Laufeyson of the Nordic Alfar
local s,id=GetID() 
function s.initial_effect(c)

	aux.AddCodeList(c,67098114)

	-------------------------------------------------
	-- Special Summon from hand
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,100000037)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- Send 1 Nordic from Deck to GY
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,100000037+100)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-------------------------------------------------
	-- Negate Spell/Trap
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,100000037+200)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
	
	local e4g=e4:Clone()
	e4g:SetRange(LOCATION_GRAVE)
	c:RegisterEffect(e4g)
end

-------------------------------------------------
-- Shared Nordic/Aesir filter
-------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0x42) or c:IsSetCard(0x4b))
end

-------------------------------------------------
-- Special Summon condition
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
		or Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

-------------------------------------------------
-- Send Nordic to GY
-------------------------------------------------
function s.tgfilter(c)
	return c:IsSetCard(0x42) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-------------------------------------------------
-- Negate Spell/Trap
-------------------------------------------------
function s.lokifilter(c)
	return c:IsFaceup() and c:IsCode(67098114)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp
		and Duel.IsExistingMatchingCard(s.lokifilter,tp,LOCATION_MZONE,0,1,nil)
		and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and Duel.IsChainDisablable(ev)
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
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,re:GetHandler(),1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end