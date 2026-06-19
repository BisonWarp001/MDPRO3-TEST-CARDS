-- Summoning the God Slime
local s,id,o=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,42166000)
	-- (1) Efecto de Activación (Quick-Play Spell)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_MAIN_END+TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- (2) Efecto en el Cementerio
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon) -- Condición oficial corregida
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (1): INVOCACIÓN ESPECIAL
-- ====================================================================================

-- Filtro limpio para mandar 1 "Slime" de mano o Deck al GY
function s.tgfilter(c)
	return c:IsSetCard(0x54b) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

-- Filtro para invocar desde el Extra Deck
function s.spfilter(c,e,tp)
	return (c:IsCode(42166000) or c:IsSetCard(0x54b)) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false,POS_FACEUP)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	-- Send 1 Slime monster from hand or Deck to GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	if #tg==0 then return end

	if Duel.SendtoGrave(tg,REASON_EFFECT)==0 then
		return
	end

	-- Special Summon from Extra Deck
	if Duel.GetLocationCountFromEx(tp,tp,nil,nil)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=sg:GetFirst()
	if not tc then return end

	if Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)~=0 then
		tc:CompleteProcedure()
	end

	-- Activation lock
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	Duel.RegisterEffect(e1,tp)
end

-- Condición del candado corregida: Solo detiene activación de efectos de MONSTRUOS
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER)
		and rc:IsSummonType(SUMMON_TYPE_SPECIAL)
		and rc:IsLocation(LOCATION_MZONE)
		and rc:IsSummonLocation(LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (2): EFECTO EN EL GY (REGRESAR A LA MANO)
-- ====================================================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return e:GetHandler():GetTurnID()~=Duel.GetTurnCount()
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,0)
			and Duel.CheckReleaseGroupEx(tp,aux.TRUE,1,REASON_COST)
	end

	aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,1)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectReleaseGroupEx(tp,aux.TRUE,1,1,REASON_COST)
	Duel.Release(g,REASON_COST)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsAbleToHand()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsAbleToHand,tp,
			LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,
		LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsAbleToHand() then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end