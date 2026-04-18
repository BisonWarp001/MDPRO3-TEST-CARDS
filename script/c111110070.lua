-- Aura of Despair
local s,id=GetID()
function s.initial_effect(c)
	-- Mencionar a Dreadroot
	aux.AddCodeList(c,62180201)
	
	-- (1) Activar: Negar efectos de los más débiles (Quick-Play)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Protección Thunderforce: El oponente no puede responder a esta carta
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetHintTiming(TIMINGS_CHECK_MONSTER,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- (2) GY Effect: Borrado total y Curación
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.condition)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- Condición: Dreadroot debe estar boca arriba en tu campo
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,62180201),tp,LOCATION_MZONE,0,1,nil)
end

-- Lógica de Negación: Apaga a todos los que ya fueron debilitados por Dreadroot
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g_dread=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode,62180201),tp,LOCATION_MZONE,0,nil)
	if #g_dread==0 then return end
	local max_atk=g_dread:GetMax(Card.GetAttack)
	
	-- Captura a todos los monstruos con menos ATK (gracias al /2 de Dreadroot, serán casi todos)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil):Filter(function(c) return c:GetAttack()<max_atk end,nil)
	
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

-- Lógica de GY: Destruye y recupera LP basado en el ATK actual (el ATK ya dividido)
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_MZONE)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g_dread=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode,62180201),tp,LOCATION_MZONE,0,nil)
	if #g_dread==0 then return end
	local max_atk=g_dread:GetMax(Card.GetAttack)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil):Filter(function(c) return c:GetAttack()<max_atk end,nil)
	
	if #g>0 then
		local rec=0
		for tc in aux.Next(g) do
			rec=rec+math.max(0,tc:GetAttack())
		end
		if Duel.Destroy(g,REASON_EFFECT)>0 then
			Duel.Recover(tp,rec,REASON_EFFECT)
		end
	end
end
