-- Great Magus, Priest of Darkness

local s,id=GetID()
function s.initial_effect(c)

	-- Enable Ritual Summon procedure using "Dark Summoning Ritual"
	c:EnableReviveLimit()
	aux.AddRitualProcGreaterCode(c,130000522)
	aux.AddCodeList(c,130000537)
	c:EnableCounterPermit(0x90)
	c:SetCounterLimit(0x90,7)

	-- ①: Add 1 "Millennium Spellbook" Spell/Trap to hand when Ritual Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: Add counter when a Spell/Trap is activated
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(aux.chainreg)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.acop)
	c:RegisterEffect(e3)

	-- ③: Destroy 1 card by removing a counter
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- ④: Gain ATK based on counters on "Millennium Stone"
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.attackup)
	c:RegisterEffect(e5)

	-- ⑤: Quick Effect to distribute "Millennium" Counters to "Millennium Stone"
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.ctcon)
	e6:SetTarget(s.cttg)
	e6:SetOperation(s.ctop)
	c:RegisterEffect(e6)

end

-- ①: Condition: Ensure this card was Ritual Summoned
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL)
end

-- ①: Target: Search for "Millennium Spellbook" Spell and add it to hand
function s.thfilter(c)
	return c:IsCode(130000532) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
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

-- ③: Add a "Millennium" Counter when a Spell/Trap is activated
function s.acop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and e:GetHandler():GetFlagEffect(FLAG_ID_CHAINING)>0 then
		e:GetHandler():AddCounter(0x90,1)
	end
end

-- ③: Cost: Remove 1 "Millennium" Counter to destroy an opponent's card
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,0,0x90,1,REASON_COST) end
	Duel.RemoveCounter(tp,1,0,0x90,1,REASON_COST)
end

-- ③: Target 1 card to destroy
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsControler(1-tp) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- Filter for "Millennium Stone"
function s.filter1(c)
	return c:IsFaceup() and c:IsCode(130000537)
end

-- ④: Gain ATK based on the number of "Millennium" Counters on "Millennium Stone"
function s.attackup(e,c)
	local g=Duel.GetMatchingGroup(s.filter1,c:GetControler(),LOCATION_SZONE,0,nil)
	local tc=g:GetFirst()
	local total_counters=0
	while tc do
		total_counters=total_counters+tc:GetCounter(0x90) 
		tc=g:GetNext()
	end
	return total_counters * 250 -- Gain 250 ATK per "Millennium" Counter
end

-- ⑤: Condition for distributing "Millennium" Counters (Millennium Stone must be face-up)
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_SZONE,0,1,nil)
end

-- ⑤: Target: "Millennium Stone" must be face-up
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetCounter(0x90)>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.filter1,tp,LOCATION_SZONE,0,1,1,nil)
end

-- ⑤: Operation: Move "Millennium" Counters from this card to "Millennium Stone"
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and c:GetCounter(0x90)>0 then
		local max_counters=c:GetCounter(0x90) -- Get the number of counters on this card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
		local ct=Duel.AnnounceNumber(tp,1,max_counters) -- Choose how many counters to move
		c:RemoveCounter(tp,0x90,ct,REASON_EFFECT) -- Remove counters from this card
		tc:AddCounter(0x90,ct) -- Add counters to "Millennium Stone"
	end
end
