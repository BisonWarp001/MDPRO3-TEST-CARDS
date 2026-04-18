--Edict of the Annihilator God
local s,id=GetID()  

function s.initial_effect(c)
	-- Code list (Obelisk y Ancient Chant para el bloqueo)
	aux.AddCodeList(c,10000000)

	-------------------------------------------------
	-- ① Activate: Add Obelisk + Extra Tribute Summon
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY: Banish; Special Summon 2 Slime Tokens
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	-- HOPT para el efecto de GY (independiente de la activación)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.tkcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search Obelisk
-------------------------------------------------
function s.thfilter(c)
	return c:IsCode(10000000) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Búsqueda
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)

		-- Invocación Adicional (Compartida con Ancient Chant 78665705)
		if Duel.GetFlagEffect(tp,78665705)==0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(aux.Stringid(id,2))
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
			e1:SetTargetRange(LOCATION_HAND,0)
			e1:SetValue(0x1)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_EXTRA_SET_COUNT)
			Duel.RegisterEffect(e2,tp)

			Duel.RegisterFlagEffect(tp,78665705,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

-------------------------------------------------
-- Token logic
-------------------------------------------------
function s.obfilter(c)
	return c:IsFaceup() and c:IsCode(10000000)
end

function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.obfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and Duel.IsPlayerCanSpecialSummonMonster(tp,111110021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,111110021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER) then return end

	for i=1,2 do
		local token=Duel.CreateToken(tp,111110021)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
	end
	Duel.SpecialSummonComplete()
end
