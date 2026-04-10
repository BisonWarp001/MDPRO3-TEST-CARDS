-- The Winged Dragon of Ra - Solar Deity
local s,id=GetID()

function s.initial_effect(c)
	-- Invocación Normal (3 tributos, no Set, no negable)
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetCondition(s.ttcon)
	e1:SetOperation(s.ttop)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e1)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SET_PROC)
	e2:SetCondition(s.setcon)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e3)

	-- Bloqueo de activación del oponente al ser Normal Summoned
	local e_sum_block=Effect.CreateEffect(c)
	e_sum_block:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_sum_block:SetCode(EVENT_SUMMON_SUCCESS)
	e_sum_block:SetOperation(s.sumsuc)
	c:RegisterEffect(e_sum_block)

	-- Inmunidad a efectos ACTIVADOS del oponente
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)

	-- (2) Check de Materiales (Gana ATK/DEF actuales de los tributos)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e5:SetCode(EFFECT_MATERIAL_CHECK)
	e5:SetValue(s.valcheck)
	c:RegisterEffect(e5)

	-------------------------------------------------
	-- (1) Efecto desde Mano: Negar GY -> Sp Summon
	-------------------------------------------------
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetRange(LOCATION_HAND)
	e6:SetCountLimit(1,id)
	e6:SetCondition(s.negcon)
	e6:SetTarget(s.negtg)
	e6:SetOperation(s.negop)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (3) Al ser Special Summoned: Pagar LP
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetCost(s.atkcost)
	e7:SetOperation(s.atkop)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- (4) Quick Effect: Pagar 1000 -> Destruir monstruos oponente
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetRange(LOCATION_MZONE)
	e8:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e8:SetCost(s.descost)
	e8:SetTarget(s.destg)
	e8:SetOperation(s.desop)
	c:RegisterEffect(e8)

	-------------------------------------------------
	-- (5) End Phase: Auto-envío (Si fue Sp Summoned)
	-------------------------------------------------
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e9:SetCategory(CATEGORY_TOGRAVE)
	e9:SetCode(EVENT_PHASE+PHASE_END)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1)
	e9:SetCondition(s.tgcon)
	e9:SetTarget(s.tgtg)
	e9:SetOperation(s.tgop)
	c:RegisterEffect(e9)

	-------------------------------------------------
	-- (6) Buscador al ir al GY
	-------------------------------------------------
	local e10=Effect.CreateEffect(c)
	e10:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e10:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e10:SetProperty(EFFECT_FLAG_DELAY)
	e10:SetCode(EVENT_TO_GRAVE)
	e10:SetCondition(s.srchcon)
	e10:SetTarget(s.srchtg)
	e10:SetOperation(s.srchop)
	c:RegisterEffect(e10)
end

-- Auxiliares Summon / Protección
function s.ttcon(e,c,minc)
	if c==nil then return true end
	return minc<=3 and Duel.CheckTribute(c,3)
end
function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,3,3)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end
function s.efilter(e,te)
	return te:IsActivated() and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

-- (2) Lógica ganar ATK/DEF de los materiales actuales
function s.valcheck(e,c)
	local g=c:GetMaterial()
	local atk=0
	local def=0
	local tc=g:GetFirst()
	while tc do
		atk=atk+math.max(tc:GetAttack(),0)
		def=def+math.max(tc:GetDefense(),0)
		tc=g:GetNext()
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE)
	e2:SetValue(def)
	c:RegisterEffect(e2)
end

-- (1) Negar en GY y Sp Summon
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev) 
		and (Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)&LOCATION_GRAVE)~=0
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) then
			Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end

-- (3) Pagar LP (Solo Special Summoned)
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local lp=Duel.GetLP(tp)
	if chk==0 then return Duel.CheckLPCost(tp,lp-100) end
	e:SetLabel(lp-100)
	Duel.PayLPCost(tp,lp-100)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(e:GetLabel())
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		c:RegisterEffect(e2)
	end
end

-------------------------------------------------
-- (4) Quick Effect: Pagar 1000 -> Destruir 1 monstruo
-------------------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end


-- (5) End Phase: Si fue Special Summoned
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then Duel.SendtoGrave(c,REASON_EFFECT) end
end

-- (6) Buscador
function s.srchcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_HAND+LOCATION_ONFIELD)
end
function s.srchfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(id) and c:IsAbleToHand()
end
function s.srchtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.srchfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.srchop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.srchfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
