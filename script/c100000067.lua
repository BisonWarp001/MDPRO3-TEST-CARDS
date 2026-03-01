--Unholy Synchronicity
local s,id=GetID()

function s.initial_effect(c)

	--------------------------------
	-- Solo puedes controlar 1
	--------------------------------
	c:SetUniqueOnField(1,0,id)

	--------------------------------
	-- Mencionar monstruos Wicked
	--------------------------------
	aux.AddCodeList(c,21208154,62180201,57793869)

	--------------------------------
	-- Activación
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------
	-- Efectos de inmunidad entre Wicked
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.immtg)
	e1:SetValue(s.immval)
	c:RegisterEffect(e1)

	--------------------------------
	-- Si se envía al Cementerio: añadir 1 Wicked
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

end

--------------------------------
-- Lista de códigos Wicked
--------------------------------
s.wicked_list={21208154,62180201,57793869}

function s.wicked(c)
	return c:IsCode(table.unpack(s.wicked_list))
end

--------------------------------
-- Objetivos de inmunidad
--------------------------------
function s.immtg(e,c)
	return c:IsFaceup() and s.wicked(c)
end

--------------------------------
-- Valor de inmunidad (no bloquea a sí mismo)
--------------------------------
function s.immval(e,re,c)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER)
		and rc:IsControler(c:GetControler())
		and s.wicked(rc)
		and rc~=c
end

--------------------------------
-- Filtro para búsqueda
--------------------------------
function s.thfilter(c)
	return s.wicked(c) and c:IsAbleToHand()
end

--------------------------------
-- Target de búsqueda
--------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

--------------------------------
-- Operación de búsqueda
--------------------------------
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end