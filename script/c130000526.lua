-- Kul Elna, the Cursed Ruins

local s,id=GetID()
function s.initial_effect(c)

	-- Activate only 1 "Kul Elna, the Cursed Ruins" per turn
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)
	
	-- (1) Place 2 "Millennium" Counters on "Millennium Stone" if face-up
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.ctcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	-- (2) Destroy 1 "Diabound" and 1 opponent's card, then Special Summon 1 "Diabound" from GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- (3) Draw 2 cards when "Diabound" is sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+2)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

-- (1) Condition: Check if "Millennium Stone" is face-up
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

-- Filter: Check for "Millennium Stone" is face-up and if it can add 1 counter
function s.ctfilter(c)
	return c:IsCode(130000537) and c:IsFaceup() and c:IsCanAddCounter(0x90,1)
end

-- (1) Operation: Place 1 "Millennium" Counter on "Millennium Stone"
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ctfilter,tp,LOCATION_ONFIELD,0,nil)
	local tc=g:GetFirst()
	while tc do
		tc:AddCounter(0x90,1)
		tc=g:GetNext()
	end
end

-- (2) Target 1 "Diabound" and 1 opponent's card, destroy both, then Special Summon 1 "Diabound" from GY
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dibfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,0,0)
end

function s.dibfilter(c)
	return c:IsSetCard(0xfa1) and c:IsFaceup()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	-- Select 1 "Diabound" monster you control and 1 opponent's card to destroy
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectMatchingCard(tp,s.dibfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	
	-- Destroy both selected cards
	if #g1>0 and #g2>0 and Duel.Destroy(g1,REASON_EFFECT)>0 and Duel.Destroy(g2,REASON_EFFECT)>0 then
		-- After destruction, check for space to Special Summon
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g3=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
			if #g3>0 then
				Duel.SpecialSummon(g3,0,tp,tp,true,true,POS_FACEUP)
			end
		end
	end
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xfa1) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

-- (3) Condition: Draw 2 cards if a "Diabound" is sent to the GY
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xfa1) and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end