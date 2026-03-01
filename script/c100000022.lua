-- Unleashed Divine Power--mdpro3 FINALIZADO no cambiar
local s,id=GetID()

function s.initial_effect(c)
	-- Mention Gods (searchable)
	aux.AddCodeList(c,10000000,10000010,10000020)

	-- Activate (activation & effect cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(
		EFFECT_FLAG_CANNOT_INACTIVATE
		+EFFECT_FLAG_CANNOT_DISABLE
		+EFFECT_FLAG_CAN_FORBIDDEN
	)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- FILTER: Divine-Beast Gods, not already affected
-------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and (c:IsCode(10000000) or c:IsCode(10000010) or c:IsCode(10000020))
		and c:GetFlagEffect(id)==0
end

-------------------------------------------------
-- TARGET
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
end

-------------------------------------------------
-- ACTIVATE
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	local c=e:GetHandler()

	-- Prevent reapplication
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_LEAVE,0,1)
	-- Client hint
	tc:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD+RESET_LEAVE,
		EFFECT_FLAG_CLIENT_HINT,
		1,0,
		aux.Stringid(id,2)
	)

	-- Clean existing negations
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)

	-- That monster's effects cannot be negated
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0)

	-- Common protections
	s.apply_common(tc,c)

	-- God-specific effects
	if tc:IsCode(10000010) then
		s.apply_ra(tc,c)
	elseif tc:IsCode(10000020) then
		s.apply_slifer(tc,c)
	elseif tc:IsCode(10000000) then
		s.apply_obelisk(tc,c)
	end
end

-----------------------------------------------------------
-- COMMON PROTECTIONS (TEXT-ACCURATE)
-----------------------------------------------------------
function s.apply_common(tc,c)

	-- Cannot be material for a Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(s.matval)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-- Unaffected by non-DIVINE monster effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.immval)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e2)

	-- Cannot be targeted by opponent's Spell/Trap effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetValue(function(e,re,tp)
		return tp~=e:GetHandlerPlayer()
			and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
	end)
	e3:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e3)

	-- Cannot be destroyed by opponent's Spell/Trap effects
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetValue(function(e,re,tp)
		return tp~=e:GetHandlerPlayer()
			and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
	end)
	e4:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e4)

-------------------------------------------------------
-- EFFECTS OF THIS MONSTER CANNOT BE NEGATED
-------------------------------------------------------

	-- Cannot disable this monster
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_CANNOT_DISABLE)
	e5:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e5)

-- Cannot inactivate this monster's effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CANNOT_INACTIVATE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(1,0)
	e6:SetValue(function(e,ct)
		local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
		return te and te:GetHandler()==e:GetHandler()
	end)
	e6:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e6)

-- Cannot negate this monster's effects
	local e7=e6:Clone()
	e7:SetCode(EFFECT_CANNOT_DISEFFECT)
	tc:RegisterEffect(e7)

end

-------------------------------------------------
-- RA EXCLUSIVE EFFECT
-------------------------------------------------
function s.apply_ra(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
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
	local g=Duel.GetReleaseGroup(tp):Filter(function(tc) return tc~=c end,nil)
	if chk==0 then return #g>0 end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=g:Select(tp,1,#g,nil)

	local atk,def=0,0
	for tc in aux.Next(rg) do
		atk=atk+math.max(tc:GetAttack(),0)
		def=def+math.max(tc:GetDefense(),0)
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
-- SLIFER EXCLUSIVE EFFECT
-------------------------------------------------
function s.apply_slifer(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(10000020,1))
	e1:SetCategory(CATEGORY_DEFCHANGE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.slifertg)
	e1:SetOperation(s.sliferop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	tc:RegisterEffect(e2)
end

function s.sliferfilter(c,tp)
	return c:IsControler(tp)
		and c:IsPosition(POS_FACEUP_DEFENSE)
end

function s.slifertg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.sliferfilter,1,nil,1-tp)
	end
	local g=eg:Filter(s.sliferfilter,nil,1-tp)
	Duel.SetTargetCard(g)
end

function s.sliferop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetsRelateToChain():Filter(Card.IsFaceup,nil)
	local dg=Group.CreateGroup()

	for tc in aux.Next(g) do
		local predef=tc:GetDefense()

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_DEFENSE)
		e1:SetValue(-2000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		if predef>0 and tc:GetDefense()==0 then
			dg:AddCard(tc)
		end
	end

	Duel.Destroy(dg,REASON_EFFECT)
end

-------------------------------------------------
-- OBELISK EXCLUSIVE EFFECT (CORREGIDO)
-------------------------------------------------
function s.apply_obelisk(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(TIMING_BATTLE_PHASE)
	e1:SetCondition(s.obcon)
	e1:SetCost(s.obcost)
	e1:SetTarget(s.obtg)
	e1:SetOperation(s.obop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

-- Only during opponent's Battle Phase
function s.obcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase() and Duel.GetTurnPlayer()~=tp
end

-- Cost: Tribute exactly 2 other monsters
function s.obcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetReleaseGroup(tp):Filter(function(tc) return tc~=c end,nil)
	if chk==0 then return #g>=2 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=g:Select(tp,2,2,nil)
	Duel.Release(rg,REASON_COST)
end

-- Target: opponent monsters
function s.obtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

-- Operation: banish all + half ATK damage
function s.obop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end

	local atk=0
	for tc in aux.Next(g) do
		atk=atk+math.max(tc:GetAttack(),0)
	end

	local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	if ct>0 and atk>0 then
		Duel.Damage(1-tp,math.floor(atk/2),REASON_EFFECT)
	end
end

-------------------------------------------------
-- AUXILIARY VALUES
-------------------------------------------------
function s.matval(e,c)
	return not c:IsAttribute(ATTRIBUTE_DIVINE)
end

function s.immval(e,te)
	if not te:IsActiveType(TYPE_MONSTER) then return false end
	local tc=te:GetOwner()
	return tc~=e:GetOwner()
		and not tc:IsAttribute(ATTRIBUTE_DIVINE)
end

function s.sttg(e,re,tp)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and re:GetHandlerPlayer()~=e:GetHandlerPlayer()
end

function s.stindes(e,re,tp)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and re:GetHandlerPlayer()~=e:GetHandlerPlayer()
end
function s.negfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end