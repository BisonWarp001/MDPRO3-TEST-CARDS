-- Jack's Joker Knight (ID: 111110132)
local s,id=GetID()
function s.initial_effect(c)
	-- Mantenemos los originales solo en la lista de códigos para las Magias oficiales
	aux.AddCodeList(c,111110130,111110131,25652259,64788463,90876561)
	
	-- (REGLA) Nombre siempre Jack's Knight (ID Oficial: 90876561)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_CODE)
	e1:SetValue(90876561)
	c:RegisterEffect(e1)

	-- (1) Search Level 10 on Normal or Special Summon while you control Queen's & King's Joker Knight
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS) -- Disparador para Invocación Especial
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SUMMON_SUCCESS) -- Disparador para Invocación Normal
	c:RegisterEffect(e2b)

	-- (2) GY Protection (Banish)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_GY)
	e4:SetCountLimit(1,id+1)
	e4:SetCost(aux.bfgcost)
	e4:SetOperation(s.protop)
	c:RegisterEffect(e4)
end

-- Filtros específicos que buscan ÚNICAMENTE tus versiones custom boca arriba en campo
function s.qfilter(c)
	return c:IsFaceup() and c:IsCode(111110130) -- ID exacto de tu Queen's Joker Knight
end
function s.kfilter(c)
	return c:IsFaceup() and c:IsCode(111110131) -- ID exacto de tu King's Joker Knight
end

-- (1) Nueva Condición: Ambos deben estar boca arriba en tu campo al resolverse la invocación de Jack
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.qfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.kfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.thfilter(c)
	return c:IsLevel(10) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- Mantiene la estructura exacta que tenías para la búsqueda e invocación inmediata
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local sc=g:GetFirst()
		-- Tu lógica original intacta para la invocación inmediata
		if sc:IsSummonable(true,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Summon(tp,sc,true,nil)
		end
	end
end

-- (2) Lógica de Protección (Solo contra efectos del oponente)
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsLevel,10))
	e1:SetValue(aux.indoval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
