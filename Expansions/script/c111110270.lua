-- Disciple of the Gods
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,10000000,10000010,10000020)
	-------------------------------------------------
	-- (1) "If" this card is Normal or Special Summoned:
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY) -- Al usar TRIGGER_O + DELAY, el sistema del juego lo reconoce estrictamente como un efecto "If"
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-------------------------------------------------
	-- (2) End Phase: Shuffle SELF -> SET Spell/Trap from GY/Banish
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- Lógica (1): Invocación Especial y Normal Inmediata
function s.spfilter(c,e,tp)
	return c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,ft,nil,e,tp)
	
	-- Se ejecuta la invocación especial
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Inmediatamente después: Invocación Normal (Opcional)
		if Duel.IsExistingMatchingCard(Card.IsSummonable,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil,true,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
			local sg=Duel.SelectMatchingCard(tp,Card.IsSummonable,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil,true,nil)
			if #sg>0 then
				Duel.Summon(tp,sg:GetFirst(),true,nil)
			end
		end
	end
end

-------------------------------------------------
-- Lógica (2): Regresar al Deck y Setear Magia/Trampa
-------------------------------------------------
function s.setfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and (aux.IsCodeListed(c,10000000) or aux.IsCodeListed(c,10000010) or aux.IsCodeListed(c,10000020))
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck() 
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then
			Duel.SSet(tp,g)
		end
	end
end
