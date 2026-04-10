-- Awakening of the Unleashed Divinity
-- Scripted by mdpro3 - FINALIZADO
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de los Dioses (para que sea buscable por soporte)
	aux.AddCodeList(c,10000000,10000010,10000020)

	-- Activación: No puede ser negada
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- TARGET: Seleccionar 1 Dios no afectado aún
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
end

function s.filter(c)
	return c:IsFaceup()
		and (c:IsCode(10000000) or c:IsCode(10000010) or c:IsCode(10000020))
		and c:GetFlagEffect(id)==0
end

-------------------------------------------------
-- OPERACIÓN PRINCIPAL
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	local c=e:GetHandler()

	-- Registro de efecto aplicado (evita reaplicación)
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))

	-- Limpiar negaciones previas
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)

	-- Protección de efectos del Dios (No pueden ser negados)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0)

	-- Aplicar Protecciones Comunes (Material y Inmunidad)
	s.apply_common(tc,c)

	-- Aplicar Efectos Ganados específicos
	if tc:IsCode(10000010) then
		s.apply_ra(tc,c)
	elseif tc:IsCode(10000020) then
		s.apply_slifer(tc,c)
	elseif tc:IsCode(10000000) then
		s.apply_obelisk(tc,c)
	end
end

-----------------------------------------------------------
-- ① & ② PROTECCIONES COMUNES
-----------------------------------------------------------
function s.apply_common(tc,c)
	-- ① No puede ser usado como material de Invocación Especial
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(aux.FilterBoolFunction(Card.IsType,TYPE_SPECIAL))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-- ② Inmune a efectos activados del oponente
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)

	-- Impedir que sus efectos activados sean negados (Field Effect)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.negfilter)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	tc:RegisterEffect(e4)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

function s.negfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end

-------------------------------------------------
-- RA: Ganancia de ATK por tributo masivo
-------------------------------------------------
function s.apply_ra(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.racost)
	e1:SetOperation(s.raop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

function s.racost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetReleaseGroup(tp):Filter(function(rc) return rc~=c end,nil)
	if chk==0 then return #g>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=g:Select(tp,1,#g,nil)
	local atk,def=0,0
	for rc in aux.Next(rg) do
		atk=atk+math.max(rc:GetAttack(),0)
		def=def+math.max(rc:GetDefense(),0)
	end
	e:SetLabel(atk,def)
	Duel.Release(rg,REASON_COST)
end

function s.raop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() or not c:IsRelateToEffect(e) then return end
	local atk,def=e:GetLabel()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	e2:SetValue(def)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- SLIFER: Negación masiva (Quick Effect)
-------------------------------------------------
function s.apply_slifer(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetCost(s.slifercost)
	e1:SetTarget(s.slifertg)
	e1:SetOperation(s.sliferop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

function s.slifercost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.slifertg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end

function s.sliferop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local g=Duel.GetMatchingGroup(function(bc) 
		return bc:IsFaceup() and bc:GetAttack()<=c:GetAttack() 
	end,tp,0,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

-------------------------------------------------
-- OBELISK EXCLUSIVE EFFECT (REVISADO SEGÚN RAVIEL)
-- Opponent's Main/Battle: Tribute 2 -> Destroy all + 4000 ATK/DEF
-------------------------------------------------
function s.apply_obelisk(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	-- Timing para Main Phase y Battle Phase del oponente
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCondition(s.obcon)
	e1:SetCost(s.obcost)
	e1:SetTarget(s.obtg)
	e1:SetOperation(s.obop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

-- Condición: Solo Main o Battle Phase del oponente
function s.obcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()~=tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE))
end

-- Costo: Tributar exactamente 2 otros monstruos (Lógica Raviel)
function s.obcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.CheckReleaseGroup(tp,nil,2,c) end
	local g=Duel.SelectReleaseGroup(tp,nil,2,2,c)
	Duel.Release(g,REASON_COST)
end

-- Target: Monstruos del oponente
function s.obtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- Operación: Destruir y ganar 4000 ATK/DEF
function s.obop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			-- Ganancia fija de 4000 ATK
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(4000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
			-- Ganancia fija de 4000 DEF
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			c:RegisterEffect(e2)
		end
	end
end
