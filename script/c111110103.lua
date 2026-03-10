--Shadow Torment - Plasma Eel the Leech Parasite
local s,id=GetID()

function s.initial_effect(c)

	--Special Summon then equip
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

end

-------------------------------------------------
--Condition
-------------------------------------------------

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x406)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-------------------------------------------------
--Target
-------------------------------------------------

function s.eqfilter(c)
	return c:IsFaceup()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
		and chkc:IsControler(1-tp)
		and s.eqfilter(chkc)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,0,LOCATION_MZONE,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.eqfilter,tp,0,LOCATION_MZONE,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)

end

-------------------------------------------------
--Operation
-------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	if not tc or not tc:IsFaceup() or not tc:IsRelateToEffect(e) then return end

	--allow equip monster
	c:CancelToGrave()

	if not Duel.Equip(tp,c,tc) then return end

	--equip limit
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(function(e,c) return c==tc end)
	c:RegisterEffect(e1)

	--negate monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_DISABLE_EFFECT)
	c:RegisterEffect(e3)

	--burn each opponent standby
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.damcon)
	e4:SetOperation(s.damop)
	e4:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e4)
	
	--SS when sent to GY while equipped
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(1,id+100)
	e5:SetCondition(s.sscon)
	e5:SetTarget(s.sstg)
	e5:SetOperation(s.ssop)
	c:RegisterEffect(e5)

end

-------------------------------------------------
--Burn
-------------------------------------------------

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Damage(1-tp,800,REASON_EFFECT)
end

--SS when sent to GY while equipped

function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_SZONE)
end

function s.ssfilter(c,e,tp)
	return c:IsSetCard(0x406)
	and c:IsLevelBelow(4)
	and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)

	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end