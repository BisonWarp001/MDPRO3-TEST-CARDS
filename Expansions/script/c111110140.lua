-- Nordic Relic Randgrith
local s,id=GetID()
function s.initial_effect(c)
	-- Activar carta
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	-- Efecto al invocar un Aesir
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	-- Debe ser un Aesir (0x4b) boca arriba
	if not (tc:IsFaceup() and tc:IsSetCard(0x4b)) then return false end
	
	-- Verificamos si es Sincronía O si se invocó por su propio efecto
	local is_self_revive = (re and re:GetHandler()==tc and tc:GetSummonType()==SUMMON_TYPE_SPECIAL+SUMMON_VALUE_SELF)
	return tc:GetSummonType()==SUMMON_TYPE_SYNCHRO or is_self_revive
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetCard(eg)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	local c=e:GetHandler()

	-- ● LIGHT (Odin / Customs de Luz): Set 1 "Nordic Relic"
	if tc:IsAttribute(ATTRIBUTE_LIGHT) and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp, aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			local sc=g:GetFirst()
			if Duel.SSet(tp,sc)>0 then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				sc:RegisterEffect(e1)
				local e2=e1:Clone()
				e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
				sc:RegisterEffect(e2)
			end
		end
	end

	-- ● EARTH (Thor / Customs de Tierra): Special Summon 1 "Nordic" + Restricción
	if tc:IsAttribute(ATTRIBUTE_EARTH) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		and Duel.SelectYesNo(tp, aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1,0)
			e1:SetTarget(s.splimit)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end

	-- ● DARK (Loki / Customs de Oscuridad): Añadir de GY/Banish a mano
	if tc:IsAttribute(ATTRIBUTE_DARK) and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
		and Duel.SelectYesNo(tp, aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

-- Filtros
function s.setfilter(c)
	return c:IsSetCard(0x5042) and c:IsSSetable()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x42) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.thfilter(c)
	return c:IsSetCard(0x42) and c:IsAbleToHand()
end
function s.splimit(e,c)
	return not (c:IsSetCard(0x42) or c:IsSetCard(0x4b)) and c:IsLocation(LOCATION_EXTRA)
end
