-- Blasphemous Ascension
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,21208154,62180201,57793869)

	-- Activate (activation & effects cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(
		EFFECT_FLAG_CANNOT_INACTIVATE
		+EFFECT_FLAG_CANNOT_DISABLE
		+EFFECT_FLAG_CAN_FORBIDDEN
	)
	e1:SetTarget(s.target) -- legality check only (NOT targeting)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- FILTER: Wicked monsters not already affected
-------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and c:IsCode(21208154,62180201,57793869)
		and c:GetFlagEffect(id)==0
end

-------------------------------------------------
-- TARGET (Legality check only, no targeting)
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
end

-------------------------------------------------
-- ACTIVATE (CHOOSE on resolution)
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if not tc then return end

	local c=e:GetHandler()

	-- Prevent reapplication
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_LEAVE,0,1)
	tc:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD+RESET_LEAVE,
		EFFECT_FLAG_CLIENT_HINT,
		1,0,
		aux.Stringid(id,1)
	)

	-- Remove existing negations
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)

	-------------------------------------------------
	-- That monster's effects cannot be negated
	-------------------------------------------------

	-- Cannot disable
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e0)

	-- Cannot inactivate its effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_INACTIVATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetValue(function(e,ct)
		local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
		return te and te:GetHandler()==e:GetHandler()
	end)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-- Cannot negate its effects
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_DISEFFECT)
	tc:RegisterEffect(e2)

	-------------------------------------------------
	-- ADDITIONAL EFFECTS
	-------------------------------------------------

	-- Also treated as DIVINE
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ADD_ATTRIBUTE)
	e3:SetValue(ATTRIBUTE_DIVINE)
	e3:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e3)

	-- Cannot be material for a Special Summon
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e4:SetValue(1)
	e4:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e4)

	-- Unaffected by other monsters except DIVINE
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.immval)
	e5:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e5)

	-- Cannot be destroyed by Spell/Trap effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e6:SetValue(function(e,re,tp)
		return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
	end)
	e6:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e6)
end

-------------------------------------------------
-- IMMUNITY VALUE
-------------------------------------------------
function s.immval(e,te)
	if not te:IsActiveType(TYPE_MONSTER) then return false end
	local tc=te:GetOwner()
	return tc~=e:GetOwner()
		and not tc:IsAttribute(ATTRIBUTE_DIVINE)
end