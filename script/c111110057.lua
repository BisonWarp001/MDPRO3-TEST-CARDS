-- Priest of the Divine Cult terminado
local s,id=GetID()
function s.initial_effect(c)
    -- Mencionar a los 3 Dioses para aux.IsCodeListed
    aux.AddCodeList(c,10000000,10000010,10000020)
    
    -- (1) Invocación especial revelando Divine-Beast
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Efecto si hay un Dios en Campo o GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.godcon)
    e2:SetTarget(s.godtg)
    e2:SetOperation(s.godop)
    c:RegisterEffect(e2)
    
    -- (3) Robar 2 si es tributado para Divine-Beast
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,4))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_PLAYER_TARGET)
    e3:SetCode(EVENT_RELEASE)
    e3:SetCountLimit(1,id+200)
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
    c:RegisterEffect(e3)
end

-- (1) Reveal logic
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_HAND,0,1,e:GetHandler(),RACE_DIVINE) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,Card.IsRace,tp,LOCATION_HAND,0,1,1,e:GetHandler(),RACE_DIVINE)
    Duel.ConfirmCards(1-tp,g)
    Duel.ShuffleHand(tp)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) God in Field/GY logic
function s.godcon(e,tp,eg,ep,ev,re,r,rp)
    -- Quitamos aux.FaceupFilter para que detecte correctamente en el GY
    return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,RACE_DIVINE)
end

function s.thfilter(c)
    return (aux.IsCodeListed(c,10000000) or aux.IsCodeListed(c,10000010) or aux.IsCodeListed(c,10000020))
        and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.godtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=e:GetHandler():IsLocation(LOCATION_HAND) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    local b2=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    if chk==0 then return b1 or b2 end
    local opt=0
    if b1 and b2 then
        opt=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
    elseif b1 then
        opt=Duel.SelectOption(tp,aux.Stringid(id,2))
    else
        opt=Duel.SelectOption(tp,aux.Stringid(id,3))+1
    end
    e:SetLabel(opt)
    if opt==0 then
        e:SetCategory(CATEGORY_SPECIAL_SUMMON)
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
    else
        e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
    end
end
function s.godop(e,tp,eg,ep,ev,re,r,rp)
    local opt=e:GetLabel()
    if opt==0 then
        local c=e:GetHandler()
        if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND) then
            Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
        end
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end

-- (3) Draw logic
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    -- Verifica que sea tributado para una Invocación por Sacrificio de un Divine-Beast
    return rc and rc:IsRace(RACE_DIVINE) and e:GetHandler():IsReason(REASON_SUMMON)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end
