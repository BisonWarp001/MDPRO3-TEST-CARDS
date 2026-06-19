-- Awakening of the Wicked Deities
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de los Wicked Gods (Originales y Custom)
	aux.AddCodeList(c,62180201,57793869,21208154)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Inmunidad de la Magia
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c,id)
	return c:IsFaceup() and (c:IsCode(62180201,57793869,21208154)) 
		and c:GetFlagEffect(id)==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil,id) end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil,id)
	local tc=g:GetFirst()
	if not tc then return end
	local c=e:GetHandler()

	-- Registro visual y protección de efectos
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0,true)

	-- Protecciones (No material / Inmunidad)
	s.apply_common(tc,c)

	-- Efectos Ganados según el nombre
	if tc:IsCode(21208154) then -- Avatar (CAMPO + GY)
		s.apply_avatar(tc,c)
	elseif tc:IsCode(57793869) then -- Eraser
		s.apply_eraser(tc,c)
	elseif tc:IsCode(62180201) then -- Dreadroot
		s.apply_dreadroot(tc,c)
	end
end

function s.apply_common(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(aux.FilterBoolFunction(Card.IsType,TYPE_SPECIAL))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2,true)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

-------------------------------------------------
-- AVATAR: Copia desde Campo o Cementerio
-------------------------------------------------
function s.apply_avatar(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.copy_tg)
	e1:SetOperation(s.copy_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1,true)
end

function s.copy_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Filtro: Monstruos de Efecto en MZONE o GRAVE de ambos jugadores
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,e:GetHandler(),TYPE_EFFECT) end
end

function s.copy_op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,c,TYPE_EFFECT)
    local tc=g:GetFirst()
    if tc and (tc:IsFaceup() or tc:IsLocation(LOCATION_GRAVE)) then
        Duel.MajesticCopy(c,tc)
        c:SetHint(CHINT_CARD,tc:GetCode())
        
        -- ESTA LÍNEA ES LA CLAVE:
        -- Fuerza al juego a re-evaluar todos los efectos continuos en el campo inmediatamente.
        Duel.Readjust() 
    end
end

-------------------------------------------------
-- ERASER: Forced Battle + End Battle Phase
-------------------------------------------------
function s.apply_eraser(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetHintTiming(TIMING_BATTLE_START,0)
	e1:SetCountLimit(1)
	e1:SetCondition(s.bpcon)
	e1:SetTarget(s.atk_tg)
	e1:SetOperation(s.atk_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

-- Only at the start of opponent's Battle Phase
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
		and Duel.GetCurrentPhase()==PHASE_BATTLE_START
end

function s.atk_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAttackPos,tp,0,LOCATION_MZONE,1,nil)
	end
end

function s.atk_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,Card.IsAttackPos,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	-- Selected monster must attack Eraser this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_MUST_ATTACK)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	e2:SetValue(s.atklimit)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2)

	-- End Battle Phase immediately after that battle
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_BATTLED)
	e3:SetLabelObject(tc)
	e3:SetOperation(s.endbp_op)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

function s.atklimit(e,c)
	return c==e:GetHandler()
end

function s.endbp_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not tc then return end

	-- If the selected monster battled Eraser
	if (a==tc and d)
		or (d==tc and a) then

		Duel.EndBattlePhase()
		e:Reset()
	end
end
-------------------------------------------------------------------
-- DREADROOT: Sentencia "Choose" (BLOQUE COMPLETO CORREGIDO)
-------------------------------------------------------------------
function s.apply_dreadroot(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	-- Timing optimizado: Solo Main Phase y Battle Phase del rival
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_PHASE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.dreadcon)
	e1:SetTarget(s.des_tg)
	e1:SetOperation(s.des_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

-- Condición de Fase: Solo Main o Battle Phase del oponente (Rango seguro de sub-fases)
function s.dreadcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then return false end
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2 
		or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)
end

-- Target: Verificar que exista al menos 1 monstruo en el campo del rival
function s.des_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
end

-- Operación: Seleccionar al monstruo y marcarlo hasta el fin del turno
function s.des_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		-- Registra la bandera visual en el monstruo del rival
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,4))
		
		-- Crear el disparador global para la End Phase
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetLabelObject(e:GetHandler()) -- Guardamos a nuestro Dreadroot en el Label
		e1:SetOperation(s.des_end_op)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- Resolución en la End Phase: Destruir el monstruo marcado y absorber su ATK actual
function s.des_end_op(e,tp,eg,ep,ev,re,r,rp)
	local dread=e:GetLabelObject() -- Recuperamos a nuestro Dreadroot
	
	-- Buscar al monstruo en el campo del oponente que tenga la bandera asignada
	local g=Duel.GetMatchingGroup(function(c) return c:GetFlagEffect(id)>0 end,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	local tc=g:GetFirst()
	
	-- Si Dreadroot sigue boca arriba en el campo, ejecuta la sentencia
	if dread and dread:IsLocation(LOCATION_MZONE) and dread:IsFaceup() then
		local atk=tc:GetAttack() -- Captura el ATK actual exacto (considera alteraciones en campo)
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			-- Incremento permanente de ATK para Dreadroot
			local e1=Effect.CreateEffect(dread)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			dread:RegisterEffect(e1)
		end
	end
end
