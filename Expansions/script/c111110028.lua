-- Awakening of the Unleashed Divinity
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de los Dioses
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
-- TARGET
-------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and (c:IsCode(10000000) or c:IsCode(10000010) or c:IsCode(10000020))
		and c:GetFlagEffect(id)==0
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
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	local c=e:GetHandler()

	-- Registro de Flag y Client Hint visual
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))

	-- Limpiar negaciones previas y proteger efectos (No pueden ser negados)
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0,true)

	-- Aplicar Protecciones Comunes (Material e Inmunidad Reforzada)
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
-- PROTECCIONES COMUNES (LA CLAVE VS MIRRORJADE)
-----------------------------------------------------------
function s.apply_common(tc,c)
	-- ① No puede ser usado como material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(aux.FilterBoolFunction(Card.IsType,TYPE_SPECIAL))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)

	-- ② Inmune a efectos ACTIVADOS del oponente (Prioridad Máxima)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	-- Se añade UNCOPYABLE y CANNOT_DISABLE para que el motor no lo ignore en resoluciones complejas
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2,true)

	-- Impedir que sus efectos activados sean negados
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
end

function s.efilter(e,te)
	-- 1. No proteger de tus propios efectos (para que tus cartas sigan funcionando en tus Dioses)
	if te:GetOwnerPlayer()==e:GetHandlerPlayer() then return false end

	-- 2. Si el efecto se ACTIVA (como el remover de Mirrorjade o un Raigeki), el Dios es INMUNE.
	if te:IsActivated() then return true end

	-- 3. Si NO es un efecto Continuo ni de Campo (como la destrucción de Mirrorjade en la End Phase),
	-- el Dios también es INMUNE. Esto cubre los efectos residuales.
	return not te:IsHasType(EFFECT_TYPE_CONTINUOUS) and not te:IsHasType(EFFECT_TYPE_FIELD)
end


function s.negfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end

-------------------------------------------------
-- RA
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
	tc:RegisterEffect(e1,true)
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
-- SLIFER: Efecto Anime (Castigo a la DEF)
-------------------------------------------------
function s.apply_slifer(tc,c)
	-- El efecto original de Slifer ya cubre ATK, así que añadimos el de DEF
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DEFCHANGE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) -- Forzado como en el anime
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.atkcon)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=eg:Filter(Card.IsSummonPlayer,nil,1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(function(bc) return bc:IsFaceup() and bc:IsControler(1-tp) end,nil)
	local dg=Group.CreateGroup()
	for tc in aux.Next(g) do
		-- Solo afecta si está en Posición de Defensa
		if tc:IsPosition(POS_DEFENSE) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_DEFENSE)
			e1:SetValue(-2000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			if tc:GetDefense()==0 then dg:AddCard(tc) end
		end
	end
	if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
end

-------------------------------------------------
-- OBELISK: Poder Infinito (Solo ATK/DEF)
-------------------------------------------------
function s.apply_obelisk(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(TIMING_BATTLE_PHASE+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCondition(s.obcon)
	e1:SetCost(s.obcost)
	e1:SetOperation(s.obop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

function s.obcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.obcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.CheckReleaseGroup(tp,nil,2,c) end
	local g=Duel.SelectReleaseGroup(tp,nil,2,2,c)
	Duel.Release(g,REASON_COST)
end

function s.obop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		-- Ganancia masiva de ATK/DEF (999,999)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(999999)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		c:RegisterEffect(e2)
	end
end
