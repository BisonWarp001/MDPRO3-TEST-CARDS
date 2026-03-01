--Supreme Devastation of the Evil Horror
local s,id=GetID()

function s.initial_effect(c)
	-- Mention The Wicked Dreadroot
	aux.AddCodeList(c,62180201)

	-------------------------------------------------
	-- ① Protect + Destroy
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY Lock
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Target Dreadroot
-------------------------------------------------

function s.filter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.filter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end

-------------------------------------------------
-- Protect + Destroy weaker monsters
-------------------------------------------------

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	local c=e:GetHandler()

	-- Cannot be destroyed by battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)

	-- Cannot be destroyed by effects
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	tc:RegisterEffect(e2)

	-- Destroy monsters with less ATK
	local atk=math.max(tc:GetAttack(),0)

	local g=Duel.GetMatchingGroup(function(c)
		return c:IsMonster()
			and c:IsFaceup()
			and c:GetAttack()<atk
	end,tp,LOCATION_MZONE,LOCATION_MZONE,tc)

	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-------------------------------------------------
-- GY Lock Effect
-------------------------------------------------

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
	return re:IsActivated()
		and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
		and re:GetActivateLocation()==LOCATION_GRAVE
end