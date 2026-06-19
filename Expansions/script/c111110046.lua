--Altar of the Chosen Faraoh terminado
local s,id=GetID()
s.listed_series={0x4b0}
function s.initial_effect(c)
	-- (0) Activación limpia (sin restricciones de búsqueda)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	
		-- Protección: Primera vez que un Divine-Beast fuera a ser destruido
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.indtg)
	e1:SetCountLimit(1)
	e1:SetValue(s.indct)
	c:RegisterEffect(e1)

	-- (1) Búsqueda manual (Ignition)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id) -- Este ID es solo para la búsqueda
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- (2) Robo de cartas (Trigger)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.drcon)
	e3:SetOperation(s.drop)
	e3:SetCountLimit(1,id+100) -- ID diferente para no interferir con la búsqueda
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

--====================================
-- Protection
--====================================
function s.indtg(e,c)
	return c:IsFaceup() and c:IsRace(RACE_DIVINE)
end
function s.indct(e,re,r,rp)
	return (r&REASON_DESTROY)~=0
end

--====================================
-- Search "Cult"
--====================================
function s.thfilter(c)
	return c:IsSetCard(0x4b0) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,LOCATION_HAND)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
			Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	end
end

--====================================
-- Draw after Divine-Beast summon
--====================================
function s.cfilter(c,tp)
	return c:IsRace(RACE_DIVINE) and c:IsSummonPlayer(tp)
end
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,2,REASON_EFFECT)
end