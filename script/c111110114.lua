--Shadow Torment - Dark Lava Golem the Incarnation of Torment
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    
    -- Custom Synchro Summon (puede usar monstruos del oponente y elegir lado)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.syncon)
    e0:SetOperation(s.synop)
    c:RegisterEffect(e0)
    
    -- Cannot attack if on opponent field
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_ATTACK)
    e1:SetCondition(s.atkcon)
    c:RegisterEffect(e1)
    
    -- Standby Phase burn
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetOperation(s.burnop)
    c:RegisterEffect(e2)
    
    -- Quick Tribute + ATK gain
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_RELEASE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+2)
    e3:SetCondition(s.qcon)
    e3:SetTarget(s.qtg)
    e3:SetOperation(s.qop)
    c:RegisterEffect(e3)
end

-- Tuner filter
function s.tfilter(c)
    return c:IsSetCard(0x406) and c:IsType(TYPE_TUNER)
end

-- Custom Synchro condition
function s.syncon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	-- Debe existir al menos 1 Shadow Torment Tuner en tu campo
	if not Duel.IsExistingMatchingCard(s.tfilter,tp,LOCATION_MZONE,0,1,nil) then return false end

	-- Debe existir al menos 1 non-Tuner en cualquier campo
	return Duel.IsExistingMatchingCard(s.ntfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

-- non-Tuner filter
function s.ntfilter(c)
	return not c:IsType(TYPE_TUNER)
end


-- Custom Synchro operation
function s.synop(e,tp,eg,ep,ev,re,r,rp,c)

	-- Seleccionar el Tuner Shadow Torment
	local tg=Duel.GetMatchingGroup(s.tfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local tuner=tg:Select(tp,1,1,nil)

	-- Seleccionar 1+ non-Tuners (tuyos o del oponente)
	local ng=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	ng:Sub(tuner)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local nt=ng:Select(tp,1,99,nil)

	local sg=tuner+nt
	local ct=#sg

	c:SetMaterial(sg)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_SYNCHRO)

	-- Elegir lado del campo
	local to_opp=false
	if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		to_opp=true
	end

	-- Determinar quien recibe daño
	local dmg_player=tp
	if to_opp then dmg_player=1-tp end

	-- Invocar directamente en el lado elegido
	if to_opp then
		Duel.MoveToField(c,tp,1-tp,LOCATION_MZONE,POS_FACEUP,true)
		c:CompleteProcedure()
	else
		Duel.SpecialSummon(c,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
	end

	-- Daño por materiales
	Duel.Damage(dmg_player,ct*200,REASON_EFFECT)
end

-- Cannot attack if on opponent field
function s.atkcon(e)
    return e:GetHandler():GetControler()~=e:GetHandler():GetOwner()
end

-- Standby Phase burn
function s.burnop(e,tp,eg,ep,ev,re,r,rp)
    local p=e:GetHandler():GetControler()
    Duel.Damage(p,1000,REASON_EFFECT)
end

-- Quick Tribute condition
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsControler(tp)
end

-- Quick Tribute target
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsReleasable,tp,0,LOCATION_MZONE,1,nil) end
end

-- Quick Tribute operation
function s.qop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.SelectMatchingCard(tp,Card.IsReleasable,tp,0,LOCATION_MZONE,1,1,nil)
    if #g>0 and Duel.Release(g,REASON_EFFECT)>0 and c:IsFaceup() then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
    end
end