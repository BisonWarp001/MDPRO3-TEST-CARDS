-- Malicious Coston (Retrain de Double Coston)
local s,id=GetID()
function s.initial_effect(c)
	-- Lista de códigos asociados (The Wicked Avatar, Dreadroot, Eraser)
	aux.AddCodeList(c,21208154,62180201,57793869)
	
	-- (1) Invocación Especial desde la mano
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- (2) Tratar como 2 tributos para un monstruo DARK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DOUBLE_TRIBUTE)
	e2:SetValue(s.dcval)
	c:RegisterEffect(e2)
	
	-- (3) Durante tu Main Phase: Excavar, Invocar o enviar al GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE+CATEGORY_DECKDES)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.exctg)
	e3:SetOperation(s.excop)
	c:RegisterEffect(e3)
end

-- Filtro de cartas que mencionan a los Dioses Malvados
function s.cfilter(c)
	return (aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,57793869)) 
		and c:IsAbleToDeck()
end

-- Costo del Efecto (1)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,1,e:GetHandler())
	Duel.ConfirmCards(1-tp,g)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Validación para el efecto (2)
function s.dcval(e,c)
	return c:IsAttribute(ATTRIBUTE_DARK)
end

-- Target del Efecto (3) [CORREGIDO]
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
	-- Se usa SetOperationInfo estándar con cantidad 0 al ser un efecto incierto (Excavar)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_DECK)
end

-- Operación del Efecto (3) [OPTIMIZADO]
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)==0 then return end
	Duel.ConfirmDecktop(tp,1)
	local g=Duel.GetDecktopGroup(tp,1)
	local tc=g:GetFirst()
	if not tc then return end
	
	-- Comprobar si es monstruo y si es posible invocarlo
	if tc:IsType(TYPE_MONSTER)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		
		Duel.DisableShuffleCheck()
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	else
		-- Si no se invoca, va al cementerio y se baraja el mazo
		Duel.DisableShuffleCheck()
		Duel.SendtoGrave(tc,REASON_EFFECT)
		Duel.ShuffleDeck(tp)
	end
end
