--Palace of the Gods
local s,id=GetID()
function s.initial_effect(c)
	-- Soporte para buscadores y listas (IDs de los Dioses Egipcios)
	aux.AddCodeList(c,10000000,10000010,10000020)
    
	-- ACTIVACIÓN: You can only activate 1 "Palace of the Gods" per turn.
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)
    
	-- PROTECCIÓN: Level 10 or higher monsters you control cannot be targeted or be destroyed by your opponent's card effects.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsLevelAbove,10))
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
    
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)
    
	-- (1) Once per turn: Add 1 Obelisk, Slifer or Ra from Deck/GY to hand.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- (2) Once per turn: Send 1 Level 10 monster from Deck to GY; Special Summon 1 Level 10 monster from Extra Deck (Ignoring conditions).
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- Funciones del Efecto (1)
function s.thfilter(c)
	return (c:IsCode(10000000) or c:IsCode(10000010) or c:IsCode(10000020)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Funciones del Efecto (2) MODIFICADAS PARA EL LORE
function s.tgfilter(c)
	return c:IsLevel(10) and c:IsAbleToGrave()
end
function s.spfilter(c,e,tp)
	-- CORRECCIÓN: Aqua es una raza (RACE_AQUA), no un tipo
	return c:IsLevel(10) and c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_AQUA) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #sg>0 and Duel.SpecialSummon(sg,0,tp,tp,true,false,POS_FACEUP)~=0 then
			-- Candado: Bloquea activación de efectos de monstruos invocados del Extra Deck
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_ACTIVATE)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(1,0)
			e1:SetValue(s.aclimit)
			-- Modificado: Hasta el fin del PRÓXIMO turno global (Turno actual + el siguiente completo)
			e1:SetReset(RESET_PHASE+PHASE_END,2)
			Duel.RegisterEffect(e1,tp)
		end
	end
end

-- Filtro del candado adaptado al texto en inglés literal
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	-- Bloquea efectos si el monstruo fue originalmente invocado del Extra Deck (esté o no en el campo al activarse)
	return re:IsActiveType(TYPE_MONSTER) and rc:IsSummonLocation(LOCATION_EXTRA)
end