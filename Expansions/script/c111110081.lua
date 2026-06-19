-- Altar of Jashin
-- ID de la carta: Reemplaza XXXXYYYY con el ID numérico real de tu carta
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,21208154,62180201,57793869)
	
	-- Activar la carta como Magia Continua (You can only activate 1 "Altar of Jashin" per turn)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- (1) Tu oponente no puede activar cartas o efectos cuando invocas por tributo
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetOperation(s.sucop)
	c:RegisterEffect(e1)

	-- (2) Una vez por turno: Añadir 1 monstruo que mencione a los Dioses
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1) -- Soft Once Per Turn (Una vez por copia boca arriba)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- (3) Robar 2 cartas si se Invoca de Modo Normal a Avatar, Dreadroot o Eraser (Hard Once Per Turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id) -- Hard Once Per Turn por nombre ("You can only use this effect of...")
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (1): BLOQUEO DE ACTIVACIÓN (ESTILO MAGMAGESTAD / FLOOWANDEREEZE)
-- ====================================================================================
function s.sucfilter(c,tp)
	return c:IsSummonType(SUMMON_TYPE_ADVANCE) and c:IsControler(tp)
end

function s.chainlm(e,rp,tp)
	return tp==rp -- El oponente no puede encadenar nada
end

function s.sucop(e,tp,eg,ep,ev,re,r,rp)
	-- Si tú invocaste por Tributo (Advance), bloquea la ventana de respuesta del oponente
	if eg:IsExists(s.sucfilter,1,nil,tp) then
		Duel.SetChainLimitTillChainEnd(s.chainlm)
	end
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (2): BÚSQUEDA USANDO LA SINTAXIS NATIVA DE TU MOTOR
-- ====================================================================================
function s.thfilter(c)
	-- Filtro estricto con IsType(TYPE_MONSTER) y aux.IsCodeListed
	return c:IsType(TYPE_MONSTER) 
		and (aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,57793869))
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Valida que la Magia Continua siga boca arriba en el campo al resolver
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (3): ROBO POR DIOSES MALIGNOS
-- ====================================================================================
function s.drfilter(c)
	-- No requiere IsFaceup() porque EVENT_SUMMON_SUCCESS valida al entrar al campo de inmediato
	return c:IsCode(21208154,62180201,57793869)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.drfilter,1,nil) and Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
