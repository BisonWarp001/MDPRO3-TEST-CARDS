--Shadow Torment - Makyura the Shadow Destroyer
local s,id=GetID()
function s.initial_effect(c)

	--Set 1 "Shadow Torment" Trap from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_LEAVE_DECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--Activate "Shadow Torment" Traps from hand
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.handcon)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetTarget(s.handtg)
	c:RegisterEffect(e2)

	--Send facedown monster it attacks to GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.gycon)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)

end

--Condition: sent from field to GY
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD)
end

--Filter
function s.setfilter(c)
	return c:IsSetCard(0x406) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SSet(tp,tc)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--Tribute condition
function s.relfilter(c,tp)
	return c:IsControler(1-tp) and c:IsReason(REASON_RELEASE)
end

function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.relfilter,1,nil,tp)
end

function s.handtg(e,c)
	return c:IsSetCard(0x406) and c:IsType(TYPE_TRAP)
end

--Send facedown monster to GY
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	local d=Duel.GetAttackTarget()
	return d and d:IsFacedown()
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local d=Duel.GetAttackTarget()
	if d and d:IsRelateToBattle() and d:IsFacedown() then
		Duel.SendtoGrave(d,REASON_EFFECT)
	end
end