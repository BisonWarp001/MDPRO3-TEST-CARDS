--Revival Slime FINALIZADO (SetCountLimit versión)
local s,id=GetID()

function s.initial_effect(c)

	-------------------------------------------------
	-- Name becomes "Revival Jam"
	-------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetValue(31709826)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Special Summon (HOPT SetCountLimit)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id) -- HOPT automático
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- If Summoned from hand in ATK → Swap + End Phase setup
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- Sent to GY → Search Slifer S/T (HOPT SetCountLimit)
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id+1) -- HOPT automático
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- Special Summon condition
-------------------------------------------------
function s.spcon(e,tp)
	return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>=4
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

-------------------------------------------------
-- Summoned from hand in ATK
-------------------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND)
		and c:IsAttackPos()
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end

	-- Swap inmediato
	s.applyswap(c)

	-- Registrar efecto End Phase temporal
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetCondition(s.endcon)
	e1:SetOperation(s.endop)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- End Phase: Change position, then swap
-------------------------------------------------
function s.endcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsFaceup()
end

function s.endop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end

	local changed=Duel.ChangePosition(c,
		c:IsAttackPos() and POS_FACEUP_DEFENSE or POS_FACEUP_ATTACK)

	if changed>0 then
		s.applyswap(c)
	end
end

-------------------------------------------------
-- Swap base ATK/DEF
-------------------------------------------------
function s.applyswap(c)
	local batk=c:GetBaseAttack()
	local bdef=c:GetBaseDefense()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK_FINAL)
	e1:SetValue(bdef)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE_FINAL)
	e2:SetValue(batk)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search Slifer S/T
-------------------------------------------------
function s.thcon(e,tp)
	return true -- ya está limitado por SetCountLimit
end

function s.thfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
		and aux.IsCodeListed(c,10000020)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end