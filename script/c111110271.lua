--The Progenitor God of Obliteration
local s,id=GetID()

function s.initial_effect(c)
    -- Invocación de Fusión
    c:EnableReviveLimit()
    aux.AddFusionProcCode3(c,10000000,10000010,10000020,true,true)
    
    -- Invocación de Contacto: Enviando al GY (Como pediste antes)
    aux.AddContactFusionProcedure(c,Card.IsAbleToGraveAsCost,LOCATION_ONFIELD,0,Duel.SendtoGrave,REASON_COST)

    -- Restricción de Invocación
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- Invocación no puede ser negada
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e1)

    -- Al Invocar: El oponente no puede activar nada
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetOperation(s.sumsuc)
    c:RegisterEffect(e2)

    -- (1) Banish total del GY oponente + Daño
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.bancon)
    e3:SetTarget(s.bantg)
    e3:SetOperation(s.banop)
    c:RegisterEffect(e3)

    -- ATK/DEF base
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_SET_ATTACK_FINAL)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)
    local e5=e4:Clone()
    e5:SetCode(EFFECT_SET_DEFENSE_FINAL)
    e5:SetValue(s.defval)
    c:RegisterEffect(e5)

    -- Inmunidad
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_IMMUNE_EFFECT)
    e6:SetValue(s.immfilter)
    c:RegisterEffect(e6)

    -- (2) Negar 3 veces
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1))
    e7:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_CHAINING)
    e7:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(3)
    e7:SetCondition(s.negcon)
    e7:SetTarget(s.negtg)
    e7:SetOperation(s.negop)
    c:RegisterEffect(e7)

    -- Registro de stats
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e8:SetCode(EVENT_SPSUMMON_SUCCESS)
    e8:SetOperation(s.statop)
    c:RegisterEffect(e8)
end

function s.splimit(e,se,sp,st)
    return not e:GetHandler():IsLocation(LOCATION_EXTRA) or aux.ContactFusionCondition(e,se,sp,st)
end

function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
    Duel.SetChainLimitTillChainEnd(aux.False)
end

-- LÓGICA (1): EL DESTIERRO Y DAÑO
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL) and e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end

function s.banfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g=Duel.GetMatchingGroup(s.banfilter,tp,0,LOCATION_GRAVE,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*500)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.banfilter,tp,0,LOCATION_GRAVE,nil)
    if #g>0 then
        local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        if ct>0 then
            Duel.BreakEffect()
            Duel.Damage(1-tp,ct*500,REASON_EFFECT)
        end
    end
end

-- STATS Y OTROS
function s.statop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local mg=c:GetMaterial()
    local atk,def=0,0
    for tc in aux.Next(mg) do
        atk=atk+math.max(tc:GetPreviousAttackOnField(),0)
        def=def+math.max(tc:GetPreviousDefenseOnField(),0)
    end
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,atk)
    c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD,0,1,def)
end

function s.atkval(e,c) return c:GetFlagEffectLabel(id) or 0 end
function s.defval(e,c) return c:GetFlagEffectLabel(id+1) or 0 end
function s.immfilter(e,te) return te:GetOwner()~=e:GetHandler() end
function s.negcon(e,tp,eg,ep,ev,re,r,rp) return rp~=tp and Duel.IsChainNegatable(ev) end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then Duel.Destroy(rc,REASON_EFFECT) end
    end
end
