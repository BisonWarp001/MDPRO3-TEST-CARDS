-- King's Joker Knight (ID: 111110131)
local s,id=GetID()
function s.initial_effect(c)
    -- Compatibilidad con soporte oficial
    aux.AddCodeList(c,111110130,111110132,25652259,64788463,90876561)
    
    -- (REGLA) Nombre siempre King's Knight
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_CODE)
    e1:SetValue(64788463)
    c:RegisterEffect(e1)

    -- (1) Special Summon (Quick Effect)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id+10) -- Si id+5 te funciona mejor en tu core, cámbialo
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- (2) Invocar a Jack DESDE MANO/DECK (Si controlas a Queen)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.jackcon) -- Aquí validamos que esté Queen
    e3:SetTarget(s.jacktg)
    e3:SetOperation(s.jackop)
    c:RegisterEffect(e3)
    local e3b=e3:Clone()
    e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3b)

    -- (3) Buscar Magia/Trampa
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+200)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

-- Filtro para detectar a Queen (Custom u Original)
function s.qfilter(c)
    return c:IsFaceup() and (c:IsCode(111110130))
end

-- Lógica (1)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.qfilter,tp,LOCATION_MZONE,0,1,nil)
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

-- Lógica (2): Requisito de Queen en campo para invocar a Jack
function s.jackcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.qfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.jacktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,111110132) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.jackop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,111110132)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Lógica (3) corregida
function s.thfilter(c)
    -- Verificamos que sea Magia o Trampa y pueda ir a la mano
    if not (c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()) then return false end
    
    -- IDs originales: Queen (25652259), King (64788463), Jack (90876561)
    -- Usamos aux.IsCodeListed para leer el AddCodeList de las cartas del deck
    return aux.IsCodeListed(c,25652259) or aux.IsCodeListed(c,64788463) or aux.IsCodeListed(c,90876561)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
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

