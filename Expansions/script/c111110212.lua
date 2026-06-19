-- Orichalcos Gigas - Immortal Warrior
local s,id=GetID()

function s.initial_effect(c)


    -- Gana 500 ATK x veces que ESTA copia fue Invocada de Modo Especial
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_PROPERTY_SINGLE_RANGE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)

    -- Contar invocaciones especiales propias
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetOperation(s.ctop)
    c:RegisterEffect(e2)

    -- Si es mandada al GY o desterrada: Invocarse
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EVENT_REMOVE)
    c:RegisterEffect(e4)

    -- Al ser Invocada de Modo Especial: mandar 1 "Orichalcos" al GY
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_TOGRAVE)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetCountLimit(1,id+100)
    e5:SetTarget(s.tgtg)
    e5:SetOperation(s.tgop)
    c:RegisterEffect(e5)
end

-- Contar invocaciones especiales propias
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=c:GetFlagEffectLabel(id)
    if not ct then ct=0 end

    c:ResetFlagEffect(id)
    c:RegisterFlagEffect(id,0,0,1,ct+1)
end

-- ATK basado en SU contador propio
function s.atkval(e,c)
    local ct=c:GetFlagEffectLabel(id)
    return (ct or 0)*500
end

-- ATK basado en SU contador propio
function s.atkval(e,c)
    local ct=c:GetFlagEffectLabel(id)
    if not ct then
        return 0
    end
    return ct*500
end

-- Revivir
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Filtro Orichalcos
function s.tgfilter(c)
    return c:IsSetCard(0x3fc)
        and c:IsType(TYPE_MONSTER)
        and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end