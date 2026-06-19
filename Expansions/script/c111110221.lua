-- Orichalcos Shynolos
local s,id=GetID()
function s.initial_effect(c)
	-- [REGISTRO] MDPro: Ponemos la etiqueta de que esta carta menciona al Sello (111110210) y a Shunoros (111110216)
	aux.AddCodeList(c,111110210,111110216)

	-- (1) You can discard this card; add 1 "Forbidden Seal of Orichalcos", OR a Spell/Trap that mentions it from your Deck to your hand.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- (2) If this card is in the GY: You can shuffle other 1 "Orichalcos" card in your GY or banishment; Special Summon this card.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- (3) If this card is destroyed by battle or card effect: You can add 1 "Orichalcos Shunoros - The Machine of Destruction" from your hand or GY, then immediately after this effect resolves, you can Special Summon that monster, ignoring its Summoning conditions.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.shgandspg)
	e3:SetOperation(s.shgandspop)
	c:RegisterEffect(e3)
end

s.listed_series={0x3fc}

-- [COMPROBACIÓN DEL EFECTO 1] Filtro de búsqueda robusto para MDPro
function s.thfilter(c)
	return c:IsAbleToHand()
		and (c:IsCode(111110210)
		or (aux.IsCodeListed(c,111110210)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)))
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
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

-- [LÓGICA EFECTO 2] Reciclar otra carta del arquetipo para invocarse
function s.tdfilter(c,ec)
	return c:IsSetCard(0x3fc) and c:IsAbleToDeck() and c~=ec
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,c,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,c,c)
	Duel.HintSelection(g)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- [LÓGICA EFECTO 3] Añadir a la mano, LUEGO Invocar Especial saltándose restricciones (true, false)
function s.shfilter(c)
	return c:IsCode(111110216) and c:IsAbleToHand()
end
function s.shgandspg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.shfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.shgandspop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.shfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,tc)

		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and tc:IsCanBeSpecialSummoned(e,0,tp,true,false)
			and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then

			Duel.BreakEffect()
			Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end