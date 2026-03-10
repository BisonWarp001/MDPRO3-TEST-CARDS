-- Shadow Torment Verdict
local s,id=GetID()

function s.initial_effect(c)

	-- Activate (Counter Trap)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Activate from hand if opponent tributed a monster this turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)

	-- Register tribute tracker
	if not s.global_check then
		s.global_check=true

		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_RELEASE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)

		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge2:SetOperation(s.reset)
		Duel.RegisterEffect(ge2,0)
	end
end

-- Control Shadow Torment
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x406)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
	and (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE))
	and Duel.IsChainNegatable(ev)
end

-- Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
	end
end

-- Negate + destroy + damage
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		if Duel.Destroy(rc,REASON_EFFECT)~=0 then
			Duel.Damage(1-tp,1000,REASON_EFFECT)
		end
	end
end

-- Detect tributes
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		local p=tc:GetPreviousControler()
		Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
	end
end

-- Reset flags
function s.reset(e,tp,eg,ep,ev,re,r,rp)
	Duel.ResetFlagEffect(0,id)
	Duel.ResetFlagEffect(1,id)
end

-- Hand activation condition
function s.handcon(e)
	return Duel.GetFlagEffect(1-e:GetHandlerPlayer(),id)>0
end