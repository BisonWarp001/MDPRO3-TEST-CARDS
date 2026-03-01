--Gargoyle Slime
local s,id=GetID()

function s.initial_effect(c)
	aux.IsCodeListed(c,10000000)
    -------------------------------------------------
    -- ① If added to hand (except draw): SS (HOPT id)
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- ② Special Summon Slime Tokens (HOPT id+1)
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.tktg)
    e2:SetOperation(s.tkop)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- ③ If sent to GY: add Obelisk S/T (HOPT id+2)
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id+2)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-------------------------------------------------
-- ① Condition
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return not e:GetHandler():IsReason(REASON_DRAW)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-------------------------------------------------
-- ② Slime Tokens
-------------------------------------------------
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsFaceup()
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,100000021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER)
    end
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if chk==0 then
        return c:IsFaceup() and ft>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,100000021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_MZONE)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end

    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end

    local max=math.min(2, ft)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NUMBER)
    local ct=Duel.AnnounceNumber(tp,1,max)

    -- ATK reduction
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(-ct*1000)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)

    -- Special Summon Tokens
    for i=1,ct do
        if Duel.IsPlayerCanSpecialSummonMonster(tp,100000021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER) then
            local token=Duel.CreateToken(tp,100000021)
            Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
        end
    end
    Duel.SpecialSummonComplete()

    -- Extra Deck restriction
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e2:SetTargetRange(1,0)
    e2:SetTarget(s.exlimit)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end

-------------------------------------------------
-- ③ GY Search
-------------------------------------------------
function s.thfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP)
        and c:IsAbleToHand()
        and aux.IsCodeListed(c,10000000) -- Obelisk the Tormentor
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end