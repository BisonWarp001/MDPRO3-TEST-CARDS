--Shadow Torment - Melchid the Four-Faced Beast
local s,id=GetID()
function s.initial_effect(c)

	--Special Summon itself from hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--Look at opponent's hand and discard 1
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)

end

-------------------------------------------------
-- Special Summon condition
-------------------------------------------------

function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x406)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-------------------------------------------------
-- Discard effect condition
-------------------------------------------------

function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local r=c:GetReason()
	return (r&REASON_RELEASE)~=0 or (r&(REASON_SYNCHRO|REASON_XYZ))~=0
end

-------------------------------------------------
-- Target
-------------------------------------------------

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
	end
end

-------------------------------------------------
-- Operation
-------------------------------------------------

function s.disop(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g==0 then return end

	Duel.ConfirmCards(tp,g)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local sg=g:Select(tp,1,1,nil)

	Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)

	Duel.ShuffleHand(1-tp)

end