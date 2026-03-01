--Slave Slime FINALIZADO (SetCountLimit versión)
local s,id=GetID()

function s.initial_effect(c)
	-------------------------------------------------
	-- Special Summon limitation (Framegear style)
	-------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Quick Effect: SS both + negate + destroy (HOPT SetCountLimit)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCountLimit(1,id) -- HOPT automático
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- Special Summon condition (igual que Gamma)
-------------------------------------------------
function s.splimit(e,se,sp,st)
	return se:IsHasType(EFFECT_TYPE_ACTIONS)
end

-------------------------------------------------
-- Condición
-------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
end

-------------------------------------------------
-- Slime válido para invocar
-------------------------------------------------
function s.spfilter(c,e,tp)
	return (c:IsSetCard(0x54b) or c:IsCode(15771991) or c:IsCode(42166000))
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-------------------------------------------------
-- Target (SetCountLimit controla HOPT)
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return not e:GetHandler():IsStatus(STATUS_CHAINING)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(
				s.spfilter,tp,
				LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,
				0,1,nil,e,tp
			)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

-------------------------------------------------
-- Operation
-------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(
		tp,aux.NecroValleyFilter(s.spfilter),
		tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,
		0,1,1,nil,e,tp
	)
	if #g==0 then return end
	local tc=g:GetFirst()

	local fid=c:GetFieldID()
	Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP)
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,fid)
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,fid)
	Duel.SpecialSummonComplete()

	-- Restricción Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.exlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- Negar y destruir
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-------------------------------------------------
-- Extra Deck restriction
-------------------------------------------------
function s.exlimit(e,c)
	return c:IsLocation(LOCATION_EXTRA)
		and not c:IsCode(42166000) -- Egyptian God Slime
end