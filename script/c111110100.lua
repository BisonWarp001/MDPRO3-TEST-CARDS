--Shadow Torment - Gil Garth the Shadow Executioner TERMINADO CORRECTO
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
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-------------------------------------------------
	-- ② Tribute opponent monster → SS from Deck
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	e2:SetCountLimit(1,id+1)
	c:RegisterEffect(e2)

end

-------------------------------------------------
-- Filters
-------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x406)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x406)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
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
-- ② Tribute opponent monster → Special Summon
-------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(1-tp)
			and chkc:IsFaceup()
	end

	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)

end

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if tc and tc:IsRelateToEffect(e) and Duel.Release(tc,REASON_EFFECT)~=0 then

		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)

		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end

	end
end