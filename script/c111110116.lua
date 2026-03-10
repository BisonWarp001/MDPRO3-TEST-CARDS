local s,id=GetID()
function s.initial_effect(c)
    -- Synchro Summon
    aux.AddSynchroProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x406),aux.NonTuner(Card.IsSetCard,0x406),2)
    c:EnableReviveLimit()

    -- Synchro summon cannot be negated
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e1)

    -- Set ATK/DEF equal to total LP lost by both players at summon
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
    end)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
    local e2b=e2:Clone()
    e2b:SetCode(EVENT_SUMMON_SUCCESS)
    c:RegisterEffect(e2b)

    -- Cannot be targeted or destroyed by opponent's effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e4)

    -- Pay 1000 LP; destroy all opponent's monsters and inflict 500 per destroyed
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,0))
    e5:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCost(s.descost)
    e5:SetTarget(s.destg)
    e5:SetOperation(s.desop)
    c:RegisterEffect(e5)

    -- If leaves field, Special Summon 1 "Shadow Torment" monster from Deck or GY ignoring summoning conditions
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCode(EVENT_LEAVE_FIELD)
    e6:SetCountLimit(1,id+1)
    e6:SetTarget(s.sptg)
    e6:SetOperation(s.spop)
    c:RegisterEffect(e6)
end

-- ATK/DEF operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lp_lost_0 = math.max(0,8000-Duel.GetLP(0))
    local lp_lost_1 = math.max(0,8000-Duel.GetLP(1))
    local val = lp_lost_0 + lp_lost_1
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_ATTACK_FINAL)
    e1:SetValue(val)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
    c:RegisterEffect(e2)
end

-- Destroy all opponent's monsters effect
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,1000) end
    Duel.PayLPCost(tp,1000)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    if chk==0 then return #g>0 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*500)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    local ct=Duel.Destroy(g,REASON_EFFECT)
    if ct>0 then
        Duel.Damage(1-tp,ct*500,REASON_EFFECT)
    end
end

-- Special Summon "Shadow Torment" monster when leaves field
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x406) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)
    end
end