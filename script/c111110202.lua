-- Slifer the Dragon of the Thunderous Sky
local s,id=GetID()

function s.initial_effect(c)

	-------------------------------------------------
	-- Invocación Normal (3 tributos, no Set, no negable)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
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

	-- Bloqueo Oponente e Inmunidad (Normal Summon)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetOperation(s.sumsuc)
	c:RegisterEffect(e4)

	-- ATK/DEF dinámico (1000 x carta en mano)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.adval)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (1) Efecto desde Mano: Niega en Mano -> Destruye -> Invoca
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_CHAINING)
	e7:SetRange(LOCATION_HAND)
	e7:SetCountLimit(1)
	e7:SetCondition(s.negcon)
	e7:SetTarget(s.negtg1)
	e7:SetOperation(s.negop1)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- (2) Segunda Boca: -2000 ATK (Summon Success)
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCode(EVENT_SUMMON_SUCCESS)
	e8:SetTarget(s.atktg)
	e8:SetOperation(s.atkop)
	c:RegisterEffect(e8)
	local e9=e8:Clone()
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e9)

	-------------------------------------------------
	-- (3) Quick Effect: Descartar 1 -> Negación Masiva
	-------------------------------------------------
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,2))
	e10:SetCategory(CATEGORY_DISABLE)
	e10:SetType(EFFECT_TYPE_QUICK_O)
	e10:SetCode(EVENT_FREE_CHAIN)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1)
	e10:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e10:SetCost(s.negcost)
	e10:SetTarget(s.negtg)
	e10:SetOperation(s.negop)
	c:RegisterEffect(e10)

	-------------------------------------------------
	-- (4) End Phase: Auto-envío
	-------------------------------------------------
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e11:SetRange(LOCATION_MZONE)
	e11:SetCode(EVENT_PHASE+PHASE_END)
	e11:SetCondition(s.tgcon)
	e11:SetOperation(s.tgop)
	c:RegisterEffect(e11)

	-------------------------------------------------
	-- (5) Al ir al GY (Mano o Campo): Buscador
	-------------------------------------------------
	local e12=Effect.CreateEffect(c)
	e12:SetDescription(aux.Stringid(id,3))
	e12:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e12:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e12:SetProperty(EFFECT_FLAG_DELAY)
	e12:SetCode(EVENT_TO_GRAVE)
	e12:SetCondition(s.srchcon)
	e12:SetTarget(s.srchtg)
	e12:SetOperation(s.srchop)
	c:RegisterEffect(e12)
end

-- Auxiliares Summon e Inmunidad
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
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.SetChainLimitTillChainEnd(s.oppchainlm)
	if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
function s.oppchainlm(e,rp,tp)
	return tp==rp
end
function s.efilter(e,te)
	return te:IsActivated() and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.adval(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_HAND,0)*1000
end

-- (1) Lógica desde mano (Niega en Mano -> Invoca)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev) 
		and Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)==LOCATION_HAND
end
function s.negtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.negop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Negar la activación (esto siempre funciona si la cadena es legal)
	if Duel.NegateActivation(ev) then
		-- Si se negó con éxito y el Dios sigue en mano
		if c:IsRelateToEffect(e) then
			-- Invocación OBLIGATORIA ignorando condiciones
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
			end
		end
	end
end

-------------------------------------------------
-- Lógica Rayo de Segunda Boca (Corregida)
-------------------------------------------------
function s.atkfilter(c,tp)
	return c:IsControler(tp) and c:IsPosition(POS_FACEUP_ATTACK)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.atkfilter,1,nil,1-tp) end
	local g=eg:Filter(s.atkfilter,nil,1-tp)
	Duel.SetTargetCard(g)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e):Filter(Card.IsFaceup,nil)
	local dg=Group.CreateGroup()
	local tc=g:GetFirst()
	while tc do
		local preatk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-2000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		
		-- Si llega a 0, marcar para destruir + Negación Plus si es Normal Summon
		if preatk~=0 and tc:IsAttack(0) then 
			dg:AddCard(tc) 
			if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
				local e3=e2:Clone()
				e3:SetCode(EFFECT_DISABLE_EFFECT)
				tc:RegisterEffect(e3)
			end
		end
		tc=g:GetNext()
	end
	if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
end

-- Slifer the Dragon of the Thunderous Sky
local s,id=GetID()

function s.initial_effect(c)
	-- No puede ser Especial Summoned (Excepto por sus propios efectos)
	c:EnableReviveLimit()

	-------------------------------------------------
	-- INVOCACIÓN NORMAL (3 tributos, no Set, no negable)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
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

	-------------------------------------------------
	-- PROTECCIÓN PERMANENTE (Inmunidad a efectos activados)
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)

	-- Bloqueo de respuesta del oponente al ser Normal Summoned
	local e_sum_block=Effect.CreateEffect(c)
	e_sum_block:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_sum_block:SetCode(EVENT_SUMMON_SUCCESS)
	e_sum_block:SetOperation(s.sumsuc)
	c:RegisterEffect(e_sum_block)

	-- ATK/DEF dinámico (1000 x carta en mano)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.adval)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (1) Efecto desde Mano: Niega en Mano -> Destruye -> Invoca
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_CHAINING)
	e7:SetRange(LOCATION_HAND)
	e7:SetCountLimit(1,id)
	e7:SetCondition(s.negcon)
	e7:SetTarget(s.negtg1)
	e7:SetOperation(s.negop1)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- (2) Segunda Boca: -2000 ATK (Summon Success)
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCode(EVENT_SUMMON_SUCCESS)
	e8:SetTarget(s.atktg)
	e8:SetOperation(s.atkop)
	c:RegisterEffect(e8)
	local e9=e8:Clone()
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e9)

	-------------------------------------------------
	-- (3) Quick Effect: Descartar 1 -> Negación Masiva
	-------------------------------------------------
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,2))
	e10:SetCategory(CATEGORY_DISABLE)
	e10:SetType(EFFECT_TYPE_QUICK_O)
	e10:SetCode(EVENT_FREE_CHAIN)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1)
	e10:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e10:SetCost(s.negcost)
	e10:SetTarget(s.negtg)
	e10:SetOperation(s.negop)
	c:RegisterEffect(e10)

	-------------------------------------------------
	-- (4) End Phase: Auto-envío
	-------------------------------------------------
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e11:SetRange(LOCATION_MZONE)
	e11:SetCountLimit(1)
	e11:SetCode(EVENT_PHASE+PHASE_END)
	e11:SetCondition(s.tgcon)
	e11:SetTarget(s.tgtg)
	e11:SetOperation(s.tgop)
	c:RegisterEffect(e11)

	-------------------------------------------------
	-- (5) Al ir al GY (Mano o Campo): Buscador
	-------------------------------------------------
	local e12=Effect.CreateEffect(c)
	e12:SetDescription(aux.Stringid(id,3))
	e12:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e12:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e12:SetProperty(EFFECT_FLAG_DELAY)
	e12:SetCode(EVENT_TO_GRAVE)
	e12:SetCondition(s.srchcon)
	e12:SetTarget(s.srchtg)
	e12:SetOperation(s.srchop)
	c:RegisterEffect(e12)
end

-- Auxiliares Summon e Inmunidad
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
	Duel.SetChainLimitTillChainEnd(s.oppchainlm)
end
function s.oppchainlm(e,rp,tp)
	return tp==rp
end
function s.adval(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_HAND,0)*1000
end

-- (1) Lógica desde mano (Niega en Mano -> Invoca)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev) 
		and Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)==LOCATION_HAND
end
function s.negtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.negop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and Duel.Destroy(eg,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end

-- (2) Lógica Rayo de Segunda Boca
function s.atkfilter(c,tp)
	return c:IsControler(tp) and c:IsPosition(POS_FACEUP_ATTACK)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.atkfilter,1,nil,1-tp) end
	local g=eg:Filter(s.atkfilter,nil,1-tp)
	Duel.SetTargetCard(g)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e):Filter(Card.IsFaceup,nil)
	local dg=Group.CreateGroup()
	for tc in aux.Next(g) do
		local preatk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-2000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		if preatk~=0 and tc:IsAttack(0) then 
			dg:AddCard(tc) 
			if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
				local e3=e2:Clone()
				e3:SetCode(EFFECT_DISABLE_EFFECT)
				tc:RegisterEffect(e3)
			end
		end
	end
	if #dg>0 then Duel.Destroy(dg,REASON_EFFECT) end
end

-- (3) Negación Masiva
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

-- (4) End Phase
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

-- (5) Buscador
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
