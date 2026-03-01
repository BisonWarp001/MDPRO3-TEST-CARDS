-- Diabound Kernel LV 6

local s,id=GetID()
function s.initial_effect(c)
 
	-- (1) Cannot be destroyed by battle once per turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetValue(s.indcon)
	c:RegisterEffect(e1)
	
	-- (2) Halve the ATK of a monster this card battles
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_CONFIRM)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- (3) Cannot activate Spell/Trap Cards until the end of the Damage Step
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1)
	e3:SetValue(s.aclimit)
	e3:SetCondition(s.actcon)
	c:RegisterEffect(e3)
	
	-- (4) Special Summon "Diabound Kernel LV 8" during the End Phase
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetCondition(s.spcon)
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

s.lvup={130000502}
s.lvdn={130000500}

-- (1) Cannot be destroyed by battle once per turn
function s.indcon(e,re,r,rp)
	return bit.band(r,REASON_BATTLE)~=0
end

-- (2) Condition: Halve the ATK of a monster this card battles
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp) and bc:IsFaceup()
end

-- (2) Operation: Halve the ATK of a monster this card battles
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if bc and bc:IsFaceup() then
		local atk=bc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-math.floor(atk/2))
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE_CAL)
		bc:RegisterEffect(e1)
	end
end

-- (3) Condition: Prevent Spell/Trap activation during this card's attack
function s.actcon(e)
	return Duel.GetAttacker()==e:GetHandler()
end

-- (3) Operation: Prevent opponent from activating Spell/Trap during this card's attack
function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE)
end

-- (4) Condition: During the End Phase, Special Summon "Diabound Kernel LV 8"
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return tp==Duel.GetTurnPlayer()
end

-- (4) Send "Diabound Kernel II" to the Grave as cost to Special Summon "Diabound Kernel LV 8"
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

-- (4) Filter to Special Summon "Diabound Kernel LV 8"
function s.spfilter(c,e,tp)
	return c:IsCode(130000502) and c:IsCanBeSpecialSummoned(e,SUMMON_VALUE_LV,tp,true,true)
end

-- (4) Target: Special Summon "Diabound Kernel LV 8" from hand or Deck
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- (4) Operation: Special Summon "Diabound Kernel LV 8"
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,SUMMON_VALUE_LV,tp,tp,true,true,POS_FACEUP)
		tc:CompleteProcedure()
	end
end
