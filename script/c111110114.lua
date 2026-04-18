--Shadow Torment - Dark Lava Golem the Incarnation of Torment
local s,id=GetID()

function s.initial_effect(c)

    -- Synchro Summon
    aux.AddSynchroProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x406),aux.NonTuner(nil),1)
    c:EnableReviveLimit()

    -------------------------------------------------
    -- Give control to opponent + burn
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.givecon)
    e1:SetOperation(s.giveop)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- Cannot attack if opponent controls it
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ATTACK)
    e2:SetCondition(s.atkcon)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- Standby Phase burn
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetOperation(s.burnop)
    c:RegisterEffect(e3)

    -------------------------------------------------
    -- Quick Tribute + ATK gain
    -------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_RELEASE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.trcon)
    e4:SetTarget(s.trtg)
    e4:SetOperation(s.trop)
    c:RegisterEffect(e4)

end

-------------------------------------------------
-- Give control condition
-------------------------------------------------

function s.givecon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsControler(tp)
end

-------------------------------------------------
-- Shadow Torment GY filter
-------------------------------------------------

function s.gyfilter(c)
    return c:IsSetCard(0x406) and c:IsType(TYPE_MONSTER)
end

-------------------------------------------------
-- Give control operation
-------------------------------------------------

function s.giveop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local ct=Duel.GetMatchingGroupCount(s.gyfilter,tp,LOCATION_GRAVE,0,nil)

    if Duel.GetControl(c,1-tp) then
        if ct>0 then
            Duel.Damage(1-tp,ct*200,REASON_EFFECT)
        end
    end

end

-------------------------------------------------
-- Cannot attack if opponent controls it
-------------------------------------------------

function s.atkcon(e)
    local c=e:GetHandler()
    return c:GetControler()~=c:GetOwner()
end

-------------------------------------------------
-- Standby Phase burn
-------------------------------------------------

function s.burnop(e,tp,eg,ep,ev,re,r,rp)
    local p=e:GetHandler():GetControler()
    Duel.Damage(p,1000,REASON_EFFECT)
end

-------------------------------------------------
-- Tribute condition
-------------------------------------------------

function s.trcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsControler(tp)
end

-------------------------------------------------
-- Tribute target
-------------------------------------------------

function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsReleasable,tp,0,LOCATION_MZONE,1,nil)
    end
end

-------------------------------------------------
-- Tribute operation
-------------------------------------------------

function s.trop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
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