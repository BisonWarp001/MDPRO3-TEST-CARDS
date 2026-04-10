-- Awakening of the Divine-Beasts terminado
local s,id=GetID()
function s.initial_effect(c)
	-- Lista de códigos de los Dioses para que IsCodeListed funcione
	aux.AddCodeList(c,10000000,10000010,10000020)
	
	-- (1) Añadir 1 Dios y 1 Soporte + Descartar
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- (2) Banishear para Invocación por Sacrificio de 2 (Ignorando condiciones)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
end

-- Filtros Efecto (1)
function s.thfilter1(c,tp)
	return not c:IsCode(id) 
		and (aux.IsCodeListed(c,10000000) or aux.IsCodeListed(c,10000010) or aux.IsCodeListed(c,10000020))
		and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,c)
end

function s.thfilter2(c)
	return c:IsRace(RACE_DIVINE) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,1)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter1),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp)
	if #g1>0 then
		local tc=g1:GetFirst()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g2=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,tc)
		g1:Merge(g2)
		if #g1==2 and Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g1)
			Duel.ShuffleHand(tp)
			Duel.BreakEffect()
			Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	end
end

-- Lógica Efecto (2): Invocación con 2 tributos
function s.sumfilter(c)
	return c:IsRace(RACE_DIVINE) and c:IsSummonable(true,nil)
end

function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- Verificación temporal de tributos
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_SET_TRIBUTE)
		e1:SetTargetRange(LOCATION_HAND,0)
		e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_DIVINE))
		e1:SetValue(2)
		Duel.RegisterEffect(e1,tp)
		local res=Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND,0,1,nil)
		e1:Reset()
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	-- Reducir tributos a 2 para Divine-Beast
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SET_TRIBUTE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_DIVINE))
	e1:SetValue(2)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- Realizar la invocación ignorando condiciones (true)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end
