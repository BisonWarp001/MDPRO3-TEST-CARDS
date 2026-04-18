-- Divine Manifestation
local s,id=GetID()

function s.initial_effect(c)
	-- Registro de los 3 Dioses específicos para efectos dirigidos
	aux.AddCodeList(c,10000000,10000010,10000020)

	-------------------------------------------------
	-- ① Al activarse: Add 1 Divine-Beast + Normal Summon (Cualquier Divine-Beast)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

		-------------------------------------------------
	-- ② En GY: Banish; Special Summon (Efecto Rápido)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O) -- Cambiado de IGNITION a QUICK_O
	e2:SetCode(EVENT_FREE_CHAIN)    -- Añadido para que sea cadena libre
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

end

-- ① Lógica: Add 1 Divine-Beast + Normal Summon 1 Divine-Beast
function s.filter(c)
	return c:IsRace(RACE_DIVINE) and c:IsAbleToHand()
end

function s.sumfilter(c)
	-- IMPORTANTE: true, nil permite que el motor del juego sepa que puede tributar
	return c:IsRace(RACE_DIVINE) and c:IsSummonable(true,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		-- Añadimos ShuffleHand para limpiar la ventana de confirmación como en la original
		Duel.ShuffleHand(tp)
		
		-- Verificar si hay algo invocable (incluyendo lo que acabas de buscar)
		if Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil) 
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil)
			if #sg>0 then
				-- El tercer parámetro 'true' es el que permite realizar los 3 tributos
				Duel.Summon(tp,sg:GetFirst(),true,nil)
			end
		end
	end
end


-------------------------------------------------
-- ② Lógica: Special Summon (Solo los 3 específicos)
-------------------------------------------------
function s.spfilter(c,e,tp)
	-- Verificamos que sea uno de los 3 dioses y que pueda ser invocado especial ignorando condiciones
	return (c:IsCode(10000000,10000010,10000020))
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_REMOVED,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- Buscamos en mano (LOCATION_HAND) y desterradas (LOCATION_REMOVED)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_REMOVED,0,1,1,nil,e,tp)
	
	if #g>0 then
		local tc=g:GetFirst()
		-- IMPORTANTE: Usamos 'true' en el 5to parámetro para ignorar las condiciones de invocación,
		-- ya que los Dioses normalmente NO pueden ser invocados especialmente.
		if Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP) then
			-- Opcional: Si quieres que se envíe al GY al final del turno (como en el anime/manga)
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		end
	end
end
