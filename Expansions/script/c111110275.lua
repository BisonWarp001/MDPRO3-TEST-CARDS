--The Sky Thunderstorm God
local s,id,o=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,10000020)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Banish draw
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e2:SetCountLimit(1,id+o)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)
end

-- Filtro para Slifer el Dragón del Cielo (10000020)
function s.spfilter(c,e,tp)
	return c:IsCode(10000020) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
		-- Inmune a efectos del oponente hasta el fin del turno
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetOwnerPlayer(tp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1,true)
	end
	Duel.SpecialSummonComplete()
end

function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end

-- Registro del efecto residual (2) en el turno actual
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCondition(s.drcon)
	e1:SetOperation(s.drop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- Filtro para comprobar si controlas a Slifer en el campo
function s.sliferfilter(c)
	return c:IsCode(10000020) and c:IsFaceup()
end

-- Condición: Si un monstruo es destruido por el efecto activado de Slifer (su segunda boca)
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	return Duel.IsExistingMatchingCard(s.sliferfilter,tp,LOCATION_MZONE,0,1,nil)
		and rc:IsCode(10000020) and rc:IsControler(tp)
end

-- Operación: Cuenta cuántos monstruos fueron destruidos en ese grupo y roba esa cantidad
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	-- Filtramos solo las cartas que eran monstruos antes/durante la destrucción
	local ct=eg:FilterCount(Card.IsType,nil,TYPE_MONSTER)
	if ct>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Draw(tp,ct,REASON_EFFECT)
	end
end
