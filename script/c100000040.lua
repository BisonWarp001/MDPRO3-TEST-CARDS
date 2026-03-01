-- Valhalla, Nordic Celestial Haven (MDPro3)
local s,id=GetID()

s.listed_series={0x42,0x4b} -- Nordic / Aesir

function s.initial_effect(c)

	-------------------------------------------------
	-- ① Activate: add 1 "Nordic" monster
	-- Solo puedes activar 1 por turno (MDPro3 OATH)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg1)
	e1:SetOperation(s.thop1)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② Aesir protection (solo efectos del oponente)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.aesirtg)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)

	-------------------------------------------------
	-- ③ Reduce Level + Token (Once per turn por copia)
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1) -- SOPT por copia
	e4:SetTarget(s.sptg3)
	e4:SetOperation(s.spop3)
	c:RegisterEffect(e4)
end

-------------------------------------------------
-- ① Search Nordic monster
-------------------------------------------------

function s.thfilter1(c)
	return c:IsSetCard(0x42)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-------------------------------------------------
-- ② Aesir protection
-------------------------------------------------

function s.aesirtg(e,c)
	return c:IsSetCard(0x4b)
end

function s.indval(e,re,tp)
	return tp~=e:GetHandlerPlayer()
end

-------------------------------------------------
-- ③ Reduce Level + Summon Token
-------------------------------------------------

function s.spfilter3(c)
	return c:IsFaceup()
		and c:IsSetCard(0x42)
		and c:GetLevel()>=3
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.spfilter3(chkc)
	end
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_MZONE,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.spfilter3,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or tc:GetLevel()<3 then
		return
	end

	-- Reduce exactamente 2 niveles hasta End Phase
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-2)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)

	-- Invocar Token
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	if not Duel.IsPlayerCanSpecialSummonMonster(
		tp,100000041,0,TYPE_TOKEN+TYPE_MONSTER,
		1000,1000,2,RACE_WARRIOR,ATTRIBUTE_LIGHT
	) then return end

	local token=Duel.CreateToken(tp,100000041)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
end