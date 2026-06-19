-- Giant God Soldier
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de Obelisk the Tormentor (Código: 10000000)
	aux.AddCodeList(c,10000000)

	-- Activación: No puede ser negada, ni sus efectos negados
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- TARGET
-------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and c:IsCode(10000000) -- Obelisk the Tormentor
		and c:GetFlagEffect(id)==0 -- Que no esté afectado por esta misma carta
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
end

-------------------------------------------------
-- OPERACIÓN PRINCIPAL
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	-- Registro de Flag para evitar doble aplicación (True Ancestor Obelisk)
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))
	
	-- LIMPIEZA DE NEGACIONES PREVIAS
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)

	-- Sus efectos no pueden ser negados (EFFECT_CANNOT_DISABLE)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0,true)

	-- Impedir que la activación de sus efectos sea negada
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.negfilter)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e3,true)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	tc:RegisterEffect(e4,true)

	-- ● Your opponent cannot use it as material for a Special Summon.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	-- El valor filtra que el bloqueo se aplique únicamente si el oponente intenta usarlo
	e1:SetValue(function(e,sc,st)
		return st==1-e:GetHandlerPlayer()
	end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)

	-- ● Unaffected by your opponent's activated effects.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2,true)

	-- ● Efecto Ganado: Destrucción rápida en Main/Battle de tu oponente
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_ATTACK+TIMING_BATTLE_END)
	e5:SetCondition(s.obcon)
	e5:SetCost(s.obcost)
	e5:SetTarget(s.obtg)
	e5:SetOperation(s.obop)
	e5:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e5,true)
end

-------------------------------------------------
-- FILTROS DE PROTECCIÓN
-------------------------------------------------
function s.efilter(e,te)
	-- Inmune solo a efectos del oponente que SE ACTIVEN (Cadenas)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

function s.negfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end

-------------------------------------------------
-- EFECTO GANADO (QUICK EFFECT)
-------------------------------------------------
function s.obcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()~=tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE))
end

function s.obcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.CheckReleaseGroup(tp,nil,2,c) end
	local g=Duel.SelectReleaseGroup(tp,nil,2,2,c)
	Duel.Release(g,REASON_COST)
end

function s.obtg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- El handler (Obelisk) debe estar boca arriba y el rival debe tener al menos 1 monstruo
	if chk==0 then return e:GetHandler():IsFaceup() and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.obop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	-- Destruye y verifica si al menos 1 fue destruido satisfactoriamente
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- Cláusula "and if you do": se aplica el aumento si Obelisk sigue en el campo boca arriba
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(4000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			c:RegisterEffect(e2)
		end
	end
end
