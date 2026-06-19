-- Terror and Despair
local s,id=GetID()

function s.initial_effect(c)
	-- Lists "The Wicked Dreadroot"
	aux.AddCodeList(c,62180201)

	-- (1) Immunity
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)

	-- (2) GY effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Shared
--------------------------------------------------

function s.dreadfilter(c)
	return c:IsFaceup() and c:IsCode(62180201)
end

--------------------------------------------------
-- Effect (1)
--------------------------------------------------

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.dreadfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.dreadfilter,tp,LOCATION_MZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.dreadfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e1)
end

--------------------------------------------------
-- Effect (2)
--------------------------------------------------

function s.fieldfilter(c,atk)
	return c:IsType(TYPE_MONSTER)
		and c:GetAttack()<atk
		and c:IsAbleToRemove()
end

function s.extrafilter(c,atk)
	return c:IsType(TYPE_MONSTER)
		and c:GetBaseAttack()>=0
		and c:GetBaseAttack()<atk
		and c:IsAbleToRemove()
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.dreadfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.dreadfilter,tp,LOCATION_MZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.dreadfilter,tp,LOCATION_MZONE,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,
		LOCATION_MZONE|LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then
		return
	end

	local atk=tc:GetAttack()

	local b1=Duel.IsExistingMatchingCard(
		s.fieldfilter,tp,0,LOCATION_MZONE,1,nil,atk)

	local b2=Duel.IsExistingMatchingCard(
		s.extrafilter,tp,0,LOCATION_EXTRA,1,nil,atk)

	if not (b1 or b2) then
		return
	end

	local op

	if b1 and b2 then
		op=Duel.SelectOption(tp,
			aux.Stringid(id,2), -- Field
			aux.Stringid(id,3)) -- Extra Deck
	elseif b1 then
		op=0
	else
		op=1
	end

	local sg=nil
	local rc=nil
	local dmg=0

	-- Field
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

		sg=Duel.SelectMatchingCard(
			tp,s.fieldfilter,tp,0,LOCATION_MZONE,
			1,1,nil,atk)

		rc=sg:GetFirst()

		if not rc then return end

		dmg=math.max(0,rc:GetAttack())
	end

	-- Extra Deck
	if op==1 then
		local eg=Duel.GetMatchingGroup(
			s.extrafilter,tp,0,LOCATION_EXTRA,nil,atk)

		if #eg==0 then return end

		Duel.ConfirmCards(tp,
			Duel.GetFieldGroup(1-tp,LOCATION_EXTRA,0))

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

		sg=eg:Select(tp,1,1,nil)

		rc=sg:GetFirst()

		if not rc then return end

		dmg=math.max(0,rc:GetBaseAttack())

		Duel.ShuffleExtra(1-tp)
	end

	if Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)>0 and dmg>0 then
		Duel.BreakEffect()
		Duel.Damage(1-tp,dmg,REASON_EFFECT)
	end
end