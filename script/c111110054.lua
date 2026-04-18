-- Divine Protection terminado
local s,id=GetID()
function s.initial_effect(c)
	-- Solo puedes controlar 1
	c:SetUniqueOnField(1,0,id)
	-- Activar
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	-- (1) Protección de destrucción (Corregido para detectar al oponente)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE) 
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0) 
	e2:SetCondition(s.protcon)
	e2:SetTarget(s.indtg)
	e2:SetValue(s.indval) -- Cambio clave: usamos una función propia
	c:RegisterEffect(e2)

	-- (2) Banishear del GY para recuperar LIGHT Nivel 4 o menor
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCondition(aux.exccon) 
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

--====================================
-- Funciones de Protección (1)
--====================================

-- Condición: Solo funciona si controlas un Divine-Beast boca arriba
function s.protcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_DIVINE),tp,LOCATION_MZONE,0,1,nil)
end

-- Target: Selecciona todas tus cartas EXCEPTO esta copia
function s.indtg(e,c)
	return c~=e:GetHandler()
end

-- Valor: Solo protege de efectos del oponente (Aquí es donde Ghost Ogre se detiene)
function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

--=================================
-- Lógica (2): Recuperar LIGHT Nivel 4 o menor
--=================================
function s.thfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end
