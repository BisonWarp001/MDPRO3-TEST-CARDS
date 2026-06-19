--Sacrifices for the Evils
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,21208154,62180201,57793869)
	
	-- (1) Efecto Principal (Barajar de Mano/GY -> Invocar del Deck)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_MAIN_END|TIMING_BATTLE_START|TIMING_BATTLE_END)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- (2) Efecto en Cementerio (Soul Energy MAX!! style)
	local e2=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMING_MAIN_END|TIMING_BATTLE_START|TIMING_BATTLE_END)
	e2:SetCondition(s.thcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------------------------
-- LOGICA EFECTO (1): SHUFFLE HAND/GY -> SUMMON DECK
---------------------------------------------------------------------------------
-- Filtro de cartas a barajar (Cualquier carta de la Mano o GY)
function s.tdfilter(c)
	return c:IsAbleToDeck()
end

-- Filtro de monstruos a invocar del DECK (DARK o FIEND)
function s.spfilter(c,e,tp)
	return (c:IsAttribute(ATTRIBUTE_DARK) or c:IsRace(RACE_FIEND)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,e:GetHandler())
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>3 then ft=3 end 
	
	local ct=Duel.GetMatchingGroupCount(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if ct<ft then ft=ct end
	if ft==0 then return end

	if ft>1 and Duel.IsPlayerAffectedByEffect(tp,59822133) then ft=1 end
	
	-- Selecciona el subgrupo de cartas de la Mano o GY para regresar al Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local rg=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,e:GetHandler())
	local sg=rg:SelectSubGroup(tp,aux.TRUE,false,1,ft)
	
	if sg and #sg>0 then
		-- Envía las cartas seleccionadas al Deck y lo baraja
		if Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
			-- Cuenta cuántas cartas se barajaron exitosamente
			local bcnt=Duel.GetOperatedGroup():FilterCount(Card.IsLocation,nil,LOCATION_DECK|LOCATION_EXTRA)
			if bcnt==0 then return end
			
			-- Invoca exactamente esa misma cantidad en Posición de Defensa Boca Arriba
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,bcnt,bcnt,nil,e,tp)
			if #tg>0 then
				Duel.SpecialSummon(tg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
			end
		end
	end

	-- Candado de Invocación restrictivo por el resto del turno (DARK Fiend unicamente)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2,tp)
	
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_MSET)
	Duel.RegisterEffect(e3,tp)
end

function s.splimit(e,c)
	return not (c:IsAttribute(ATTRIBUTE_DARK) or c:IsRace(RACE_FIEND))
end

---------------------------------------------------------------------------------
-- EFECTO (2): SOPORTE SOUL ENERGY MAX!! (QUEDA INTACTO Y TOTALMENTE OPERATIVO)
---------------------------------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()>=PHASE_MAIN1 and Duel.GetCurrentPhase()<=PHASE_MAIN2
end

function s.thfilter(c)
	return (c:IsCode(21208154) or c:IsCode(62180201) or c:IsCode(57793869)) and c:IsAbleToHand()
end

function s.sumfilter(c)
	return (c:IsCode(21208154) or c:IsCode(62180201) or c:IsCode(57793869)) and c:IsSummonable(true,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		
		if Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.ShuffleHand(tp)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil)
			if #sg>0 then
				Duel.Summon(tp,sg:GetFirst(),true,nil)
			end
		end
	end
end
