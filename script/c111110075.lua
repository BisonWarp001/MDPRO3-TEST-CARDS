-- The Erasure of Life
local s,id=GetID()

function s.initial_effect(c)
	-- Mencionar a The Wicked Eraser para compatibilidad con buscadores
	aux.AddCodeList(c,57793869)

	-- (1) Activar: Incrementar estadísticas de Eraser por tus cartas controladas
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- SÓLO la activación está protegida mediante el flag nativo CANNOT_INACTIVATE
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- (2) Efecto en Cementerio: Autodestrucción Directa
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET) 
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- Filtro base para buscar a The Wicked Eraser boca arriba
function s.eraserfilter(c)
	return c:IsFaceup() and c:IsCode(57793869)
end

-------------------------------------------------------------------
-- Lógica del Efecto (1)
-------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.eraserfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.eraserfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.eraserfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	-- Registra el Client Hint (Aviso visual en los estados de Eraser)
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,2))

	-- e1: Incrementa el ATK basado en tus cartas bajo control (Se acumula con el original)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK) -- CAMBIADO: De SET_FINAL a UPDATE
	e1:SetValue(s.atkval)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	
	-- e2: Mismo incremento aplicado a la DEF
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE) -- CAMBIADO: De SET_FINAL a UPDATE
	tc:RegisterEffect(e2)
end

-- Función de cálculo: Cuenta tus cartas en zonas de juego x 1000
function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()
	return Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)*1000
end

-------------------------------------------------------------------
-- Lógica del Efecto (2)
-------------------------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.eraserfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.eraserfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.eraserfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
