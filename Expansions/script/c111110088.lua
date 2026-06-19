-- Test Card
local s,id=GetID()
function s.initial_effect(c)
    -- Lista de IDs: Dreadroot (62180201)
    aux.AddCodeList(c,62180201)
    
    -- (1) Special Summon si el oponente tiene 4 o menos cartas en mano
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Enviar 1 monstruo del Deck al GY y destruir 1 carta
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    
    -- (3) Si es enviada al GY: Recuperar S/T de Dreadroot y esta carta a la mano
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id+200)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- (1) Lógica Special Summon
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)<=4
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

-- (2) Lógica Enviar al GY y Destruir
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsMonster,tp,LOCATION_DECK,0,1,nil)
        and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsMonster,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local dg=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
        if #dg>0 then
            Duel.HintSelection(dg)
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end

-- (3) Lógica Recuperar de GY a Mano
function s.thfilter(c)
    return c:ListsCode(62180201) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() 
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,2,tp,LOCATION_GRAVE) -- "2" porque son esta carta + la Magia/Trampa
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        g:AddCard(c)
        if c:IsRelateToEffect(e) then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
