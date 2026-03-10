--Shadow Torment - Drillago the Soul Piercer
local s,id=GetID()
function s.initial_effect(c)

	--Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--Piercing damage
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)

	--Destroy S/T and grant direct attack
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

end

-------------------------------------------------
-- Special Summon condition
-------------------------------------------------

function s.spcon(e,c)
	if c==nil then return true end
	return Duel.IsExistingMatchingCard(Card.IsMonster,c:GetControler(),0,LOCATION_MZONE,1,nil)
end

-------------------------------------------------
-- Synchro material condition
-------------------------------------------------

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_SYNCHRO)~=0
end

-------------------------------------------------
-- Target Spell/Trap
-------------------------------------------------

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	local sc=e:GetHandler():GetReasonCard()

	if chkc then
		return chkc:IsOnField()
		and chkc:IsControler(1-tp)
		and chkc:IsSpellTrap()
	end

	if chk==0 then
		return sc and sc:IsSummonType(SUMMON_TYPE_SYNCHRO)
		and Duel.IsExistingTarget(Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)

end

-------------------------------------------------
-- Operation
-------------------------------------------------

function s.desop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()
	local sc=c:GetReasonCard()
	local tc=Duel.GetFirstTarget()

	if tc and tc:IsRelateToEffect(e)
	and Duel.Destroy(tc,REASON_EFFECT)>0
	and sc and sc:IsFaceup() then

		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DIRECT_ATTACK)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		sc:RegisterEffect(e1)

	end
end