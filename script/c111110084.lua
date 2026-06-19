-- Disciple of the Wicked One
-- ID de la carta: Reemplaza XXXXYYYY con el ID numérico real de tu carta
local s,id=GetID()
function s.initial_effect(c)
	-- Lista de códigos asociados (The Wicked Avatar, Dreadroot, Eraser)
	aux.AddCodeList(c,21208154,62180201,57793869)
	
	-- (1) Añadir 1 Magia/Trampa desde el Deck a la mano si hay un monstruo calificado en el GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- (2) Negate+Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end

-- Filtro 1: Monstruo que mencione a los Dioses (Usando aux.IsCodeListed)
function s.cfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,57793869))
end

-- Condición (1): Comprobación en el Cementerio usando LOCATION_GRAVE
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil)
end

-- Filtro para buscar Magias o Trampas que mencionen a los Dioses
function s.thfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and (aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,57793869))
		and c:IsAbleToHand()
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

-- Filtro para revivir del GY monstruos válidos
-- Condición (2): Un monstruo que controla el adversario activa su efecto
-- (2) When a monster your opponent controls activates its effect
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	local tc=re:GetHandler()
	return tc:IsControler(1-tp)
		and loc==LOCATION_MZONE
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainDisablable(ev)
end

-- Monstruos que mencionan a los Wicked Gods
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_MONSTER)
		and (aux.IsCodeListed(c,21208154)
			or aux.IsCodeListed(c,62180201)
			or aux.IsCodeListed(c,57793869))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and not c:IsCode(id)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				aux.NecroValleyFilter(s.spfilter),
				tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.NegateEffect(ev) then return end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.spfilter),
		tp,LOCATION_GRAVE,0,
		1,1,nil,e,tp
	)

	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end