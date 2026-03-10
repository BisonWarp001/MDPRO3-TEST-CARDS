-- Dark Pain Exchange
local s,id=GetID()
s.listed_series={0x406} -- Shadow Torment

function s.initial_effect(c)
	-- Activate: damage + send/add monster
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DAMAGE+CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)

	-- Banish from GY: inflict 500 per Shadow Torment with different name
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCountLimit(1,id+1000)
	e2:SetCost(aux.bfgcost) -- banish self
	e2:SetTarget(s.target2)
	e2:SetOperation(s.activate2)
	c:RegisterEffect(e2)
end

-- Effect 1 target
function s.filter(c)
	return c:IsSetCard(0x406) and c:IsType(TYPE_MONSTER)
end

function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,1000)
end

-- Effect 1 operation
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.Damage(tp,1000,REASON_EFFECT) or not Duel.Damage(1-tp,1000,REASON_EFFECT) then return end
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()
	if Duel.GetLP(tp)<Duel.GetLP(1-tp) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	else
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end

-- Effect 2 target
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_GRAVE,0,nil,0x406)
	local ct=g:GetClassCount(Card.GetCode)
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(ct*500)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*500)
end

-- Effect 2 operation
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end