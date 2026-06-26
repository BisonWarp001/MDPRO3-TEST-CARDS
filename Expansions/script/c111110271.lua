--The Progenitor God of Obliteration
local s,id=GetID()

function s.initial_effect(c)
    -- Fusion Summon
    c:EnableReviveLimit()
    aux.AddFusionProcCode3(c,10000000,10000010,10000020,true,true)

    -- Contact Fusion
    aux.AddContactFusionProcedure(
        c,
        Card.IsAbleToGraveAsCost,
        LOCATION_MZONE,
        0,
        function(g)
            local atk,def=0,0
            local tc=g:GetFirst()
            while tc do
                atk=atk+math.max(tc:GetAttack(),0)
                def=def+math.max(tc:GetDefense(),0)
                tc=g:GetNext()
            end

            s.material_atk=atk
            s.material_def=def

            Duel.SendtoGrave(g,REASON_COST)
        end
    )

    -- Summon restriction
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- Once per turn Special Summon
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.regcon)
    e1:SetOperation(s.regop)
    c:RegisterEffect(e1)

    -- Summon cannot be negated
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e2)

    -- No response on summon
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetOperation(s.sumsuc)
    c:RegisterEffect(e3)

    -- Register ATK/DEF on summon
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetOperation(s.statop)
    c:RegisterEffect(e5)

    -- Set ATK
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_SET_ATTACK_FINAL)
    e6:SetValue(s.atkval)
    c:RegisterEffect(e6)

    -- Set DEF
    local e7=e6:Clone()
    e7:SetCode(EFFECT_SET_DEFENSE_FINAL)
    e7:SetValue(s.defval)
    c:RegisterEffect(e7)

    -- Unaffected by other card effects
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE)
    e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCode(EFFECT_IMMUNE_EFFECT)
    e8:SetValue(s.immfilter)
    c:RegisterEffect(e8)

    -- Negate up to 3 times per turn
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,1))
    e9:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_CHAINING)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(3)
    e9:SetCondition(s.negcon)
    e9:SetTarget(s.negtg)
    e9:SetOperation(s.negop)
    c:RegisterEffect(e9)
end

-- Summon restriction
function s.splimit(e,se,sp,st)
    return Duel.GetFlagEffect(sp,id)==0
end
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end

-- No response when summoned
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
    Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

-- Store ATK/DEF
function s.statop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    local atk=s.material_atk or 0
    local def=s.material_def or 0

    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,atk)
    c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD,0,1,def)
end

function s.atkval(e,c)
    return c:GetFlagEffectLabel(id) or 0
end

function s.defval(e,c)
    return c:GetFlagEffectLabel(id+1) or 0
end

-- Immunity
function s.immfilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Negate
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end

    Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,1,0,0)

    local rc=re:GetHandler()
    if rc and rc:IsRelateToChain(ev) and rc:IsDestructable() then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc and rc:IsRelateToChain(ev) and rc:IsDestructable() then
            Duel.Destroy(rc,REASON_EFFECT)
        end
    end
end