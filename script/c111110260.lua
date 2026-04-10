--The Progenitor God of Obliteration
local s,id=GetID()

function s.initial_effect(c)
    -- Invocación de Fusión (Materiales específicos)
    c:EnableReviveLimit()
    -- Reemplaza estos IDs con los de tus cartas "Progenitor God" reales
aux.AddFusionProcCode3(c,111110250,111110251,111110252,true,true)
	aux.AddContactFusionProcedure(c,Card.IsAbleToRemoveAsCost,LOCATION_ONFIELD,0,Duel.Remove,POS_FACEUP,REASON_COST)

    -- Condición de Invocación (Crucial para que aparezca en el Extra Deck)
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

    -- (1) Banish total + Daño (Al ser invocado del Extra)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.bancon)
    e3:SetTarget(s.bantg)
    e3:SetOperation(s.banop)
    c:RegisterEffect(e3)

    -- ATK/DEF base de materiales
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

    -- Inmunidad total
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_IMMUNE_EFFECT)
    e6:SetValue(s.immfilter)
    c:RegisterEffect(e6)

    -- (2) Quick Effect: Negar hasta 3 veces por turno
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

    -- Registro de estadísticas de materiales
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e8:SetCode(EVENT_SPSUMMON_SUCCESS)
    e8:SetOperation(s.statop)
    c:RegisterEffect(e8)
end

-- Funciones de Soporte
function s.splimit(e,se,sp,st)
    return not e:GetHandler():IsLocation(LOCATION_EXTRA) or aux.ContactFusionCondition(e,se,sp,st)
end

function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
    Duel.SetChainLimitTillChainEnd(aux.False)
end

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

-- (1) Banish Monstruos del GY + Daño (Al ser invocado del Extra)
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL) and e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end

function s.gyfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g=Duel.GetMatchingGroup(s.gyfilter,tp,0,LOCATION_GRAVE,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*500)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    -- Selecciona solo monstruos en el cementerio del oponente (1-tp)
    local g=Duel.GetMatchingGroup(s.gyfilter,tp,0,LOCATION_GRAVE,nil)
    if #g>0 then
        local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        if ct>0 then
            Duel.BreakEffect()
            Duel.Damage(1-tp,ct*500,REASON_EFFECT)
        end
    end
end


function s.immfilter(e,te)
    return te:GetOwner()~=e:GetHandler()
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.Destroy(rc,REASON_EFFECT)
        end
    end
end
