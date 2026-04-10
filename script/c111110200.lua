-- Obelisk the Tormentor - The Giant God Soldier
local s,id=GetID()

function s.initial_effect(c)
	
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
	
	-------------------------------------------------
	-- (1) Efecto desde Mano: Negar -> Destruir -> Invocación ESPECIAL
	-------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_HAND)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.negcon)
	e5:SetTarget(s.negtg1)
	e5:SetOperation(s.negop1)
	c:RegisterEffect(e5)

	-------------------------------------------------
	-- (2) Quick Effect: Tribute 2 -> Board Wipe / 4000 DMG
	-------------------------------------------------
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e6:SetCost(s.descost)
	e6:SetTarget(s.destg)
	e6:SetOperation(s.desop)
	c:RegisterEffect(e6)

	-------------------------------------------------
	-- (3) Quick Effect: Negate/Destroy 1 monster (OPT)
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_FREE_CHAIN)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1)
	e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e7:SetTarget(s.distg)
	e7:SetOperation(s.disop)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- (4) End Phase: Auto-envío si fue Special Summoned
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetCode(EVENT_PHASE+PHASE_END)
	e8:SetCondition(s.tgcon)
	e8:SetTarget(s.tgtg)
	e8:SetOperation(s.tgop)
	c:RegisterEffect(e8)

	-------------------------------------------------
	-- (5) Al ir al GY: Buscador de Magia/Trampa que lo mencione
	-------------------------------------------------
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,3))
	e9:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e9:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e9:SetProperty(EFFECT_FLAG_DELAY)
	e9:SetCode(EVENT_TO_GRAVE)
	e9:SetCondition(s.srchcon)
	e9:SetTarget(s.srchtg)
	e9:SetOperation(s.srchop)
	c:RegisterEffect(e9)
end

-- Auxiliares Summon
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

-- Lógica de Inmunidad y Bloqueo
function s.efilter(e,te)
	return te:IsActivated() and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(s.oppchainlm)
end
function s.oppchainlm(e,rp,tp)
	return tp==rp
end

-- (1) Lógica desde mano
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev) 
		and Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)==LOCATION_MZONE
end
function s.negtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end 
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.negop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		if Duel.Destroy(eg,REASON_EFFECT)>0 and c:IsRelateToEffect(e) then
			Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end

-------------------------------------------------
-- (2) Quick Effect: Tribute 2 -> Board Wipe / 4000 DMG (Corregido)
-------------------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.CheckReleaseGroup(tp,Card.IsReleasable,2,c) end
    local g=Duel.SelectReleaseGroup(tp,Card.IsReleasable,2,2,c)
    Duel.Release(g,REASON_COST)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    -- REQUISITO OBLIGATORIO: El oponente debe tener al menos 1 MONSTRUO para activar el efecto
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsMonster,tp,0,LOCATION_MZONE,1,nil) end
    
    local c=e:GetHandler()
    local g
    if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
        -- Si es Normal: El objetivo visual es todo el campo, pero el check de arriba garantiza que hay un monstruo
        g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
        Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,4000)
    else
        -- Si es Special: Solo apunta a monstruos
        g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
    end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsSummonType(SUMMON_TYPE_ADVANCE) then
        -- CASO NORMAL SUMMON: Destruye TODO e inflige daño
        local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
        if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
            Duel.Damage(1-tp,4000,REASON_EFFECT)
        end
    else
        -- CASO SPECIAL SUMMON: Solo destruye MONSTRUOS
        local g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
        if #g>0 then 
            Duel.Destroy(g,REASON_EFFECT)
        end
    end
end

-- (3) Lógica Negación individual
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
		Duel.AdjustInstantly()
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- (4) Lógica End Phase Send
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

-- (5) Lógica Buscador
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
