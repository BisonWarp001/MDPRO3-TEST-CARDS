-- Little Jam MDPro3 (SetCountLimit HOPT)
local s,id=GetID()

function s.initial_effect(c)
	-------------------------------------------------
	-- ① Search on Normal / Special Summon
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	e1:SetCountLimit(1,id) -- HOPT estandar MDPro3
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-------------------------------------------------
	-- ② Tribute → Special Summon
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	e2:SetCountLimit(1,id+1) -- HOPT estandar MDPro3
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- ③ GY revive
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCondition(s.gycon)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	e3:SetCountLimit(1,id+2) -- HOPT estandar MDPro3
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- Conditions (ya no se usan flags manuales)
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return true -- Siempre verdadero, HOPT manejado por SetCountLimit
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return true -- Siempre verdadero, HOPT manejado por SetCountLimit
end

-------------------------------------------------
-- Filters
-------------------------------------------------
function s.slime(c)
	return c:IsSetCard(0x54b)
		or c:IsCode(15771991) -- Guardian Slime
		or c:IsCode(42166000) -- Egyptian God Slime
end

function s.thfilter(c)
	return s.slime(c)
		and not c:IsCode(id)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.spfilter(c,e,tp)
	return s.slime(c)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.gyfilter(c)
	return s.slime(c)
		and not c:IsCode(id)
		and c:IsAbleToDeck()
end

-------------------------------------------------
-- ① Search
-------------------------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-------------------------------------------------
-- ② Tribute → Special Summon
-------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- Excluir esta carta del conteo de espacios
		return Duel.GetLocationCount(tp,LOCATION_MZONE,e:GetHandler())>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-------------------------------------------------
-- ③ GY revive
-------------------------------------------------
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) then
			Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end