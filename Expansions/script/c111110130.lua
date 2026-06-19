--Queen's Joker Knight (ID: 111110130)
local s,id=GetID()
function s.initial_effect(c)
    aux.AddCodeList(c,111110131,111110132)

    -- (REGLA) Nombre siempre Queen's Knight
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_CODE)
    e1:SetValue(25652259)
    c:RegisterEffect(e1)

    -- (1) Special Summon desde la mano
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- (2) Add 1 King's Joker Knight (Si es Normal o Especial desde MANO)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetCountLimit(1,id+1)
    e3:SetTarget(s.addtg)
    e3:SetOperation(s.addop)
    c:RegisterEffect(e3)

    local e3b=e3:Clone()
    e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3b:SetCondition(s.hndcon)
    c:RegisterEffect(e3b)

    -- (3) If sent to GY, during End Phase recycle and add to hand
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_PHASE+PHASE_END)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,id+2)
    e4:SetTarget(s.rectg)
    e4:SetOperation(s.recop)
    c:RegisterEffect(e4)
end

-- (1) Lógica Special Summon
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        or Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end

    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) Lógica de Búsqueda
function s.hndcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_HAND)
end

function s.addtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,111110131)
    end

    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.addop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

    local g=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,111110131)

    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- (3) To hand
function s.recfilter(c)
    return (c:IsCode(111110131) or c:IsCode(111110132))
        and c:IsAbleToDeck()
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE)
            and chkc:IsControler(tp)
            and s.recfilter(chkc)
    end

    if chk==0 then
        return e:GetHandler():IsAbleToHand()
            and Duel.IsExistingTarget(s.recfilter,tp,LOCATION_GRAVE,0,1,nil)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)

    local g=Duel.SelectTarget(tp,s.recfilter,tp,LOCATION_GRAVE,0,1,1,nil)

    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()

    if tc
        and tc:IsRelateToEffect(e)
        and Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0
        and tc:IsLocation(LOCATION_DECK)
        and c:IsRelateToEffect(e) then

        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end