-- Unholy Synchronicity
local s,id=GetID()

function s.initial_effect(c)
	-- Solo puedes controlar 1 "Unholy Synchronicity"
	c:SetUniqueOnField(1,0,id)

	-- Mencionar monstruos Wicked en el registro del juego
	aux.AddCodeList(c,21208154,62180201,57793869)

	-- Activación de la Carta (Mágica/Trampa Continua)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- (1) Inmunidad propia si hay un Nivel 10 en el campo
	-- No puede ser destruido por efectos
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCondition(s.indcon)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	-- No puede ser seleccionado por efectos
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- (2) Efectos de inmunidad mutua entre monstruos Wicked
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.immtg)
	e3:SetValue(s.immval)
	c:RegisterEffect(e3)

	-- (3) Si esta carta está en el GY: Reciclar Wicked y recuperar esta carta
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

-- Lista de códigos de los monstruos Wicked
s.wicked_list={21208154,62180201,57793869}

function s.wicked(c)
	return c:IsCode(table.unpack(s.wicked_list))
end

-------------------------------------------------------------------
-- (1) Funciones para la auto-protección (Estilo Earthbound Geoglyph)
-------------------------------------------------------------------
function s.indfilter(c)
	return c:IsFaceup() and c:IsLevel(10)
end

function s.indcon(e)
	-- Revisa si existe algún monstruo nivel 10 boca arriba en cualquier lado del campo
	return Duel.IsExistingMatchingCard(s.indfilter,0,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

-------------------------------------------------------------------
-- (2) Funciones para la inmunidad mutua de los Wicked
-------------------------------------------------------------------
function s.immtg(e,c)
	return c:IsFaceup() and s.wicked(c)
end

function s.immval(e,re,c)
	local rc=re:GetHandler()
	-- Es inmune a efectos de monstruos del mismo controlador si son "Wicked" y diferentes a sí mismos
	return re:IsActiveType(TYPE_MONSTER)
		and rc:IsControler(c:GetControler())
		and s.wicked(rc)
		and rc~=c
end

-------------------------------------------------------------------
-- (3) Funciones para el efecto en el Cementerio
-------------------------------------------------------------------
-- Filtro para buscar un monstruo Wicked válido en el GY
function s.tdfilter(c)
	return s.wicked(c) and c:IsAbleToDeck()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	-- chkc es para cuando el juego re-evalúa el objetivo seleccionado
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.tdfilter(chkc) end
	-- El efecto requiere que esta carta pueda regresar a la mano
	if chk==0 then 
		return e:GetHandler():IsAbleToHand() 
			and Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil) 
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	-- El objetivo debe seguir siendo válido al resolver
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		-- Si se barajó exitosamente al Deck, añade esta carta a la mano
		if c:IsRelateToEffect(e) then
			Duel.SendtoHand(c,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,c)
		end
	end
end
