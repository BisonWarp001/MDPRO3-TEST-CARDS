-- Orichalcos Matia
-- ID: (Asegúrate de que el archivo .lua se llame igual que el ID en la base de datos)
local s,id=GetID()

function s.initial_effect(c)
    --(1) Add 3 with different names, except itself, then discard 2
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id) -- Una vez por turno
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --(2) Banish from GY, except the turn it was sent there; shuffle up to other 3, draw 1 (Modificado)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100) -- Una vez por turno (índice diferente)
    e2:SetCondition(s.drcon)
    e2:SetCost(aux.bfgcost) -- Costo: Desterrarse a sí misma
    e2:SetTarget(s.tdtg)
    e2:SetOperation(s.tdop)
    c:RegisterEffect(e2)
end

s.listed_series={0x3fc}

---------------------------------------------------
--(1) Añadir 3 Orichalcos con nombres diferentes
---------------------------------------------------

function s.thfilter(c)
    -- Evita buscar copias de "Orichalcos Matia" (id)
    return c:IsSetCard(0x3fc) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
        -- GetClassCount(Card.GetCode) verifica cuántos nombres ÚNICOS hay en el Deck
        return g:GetClassCount(Card.GetCode)>=3
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,3,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,2)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if g:GetClassCount(Card.GetCode)<3 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    -- SelectSubGroup es la forma más estable y nativa para exigir 3 cartas con nombres distintos
    local sg=g:SelectSubGroup(tp,aux.dncheck,false,3,3)
    
    if sg and #sg==3 and Duel.SendtoHand(sg,nil,REASON_EFFECT)==3 then
        Duel.ConfirmCards(1-tp,sg)
        Duel.ShuffleHand(tp)
        Duel.BreakEffect() -- Separa la búsqueda del descarte
        
        -- Descarta exactamente 2 cartas de tu mano (se usa 'nil' para que permita cualquier carta)
        Duel.DiscardHand(tp,nil,2,2,REASON_EFFECT+REASON_DISCARD)
    end
end

---------------------------------------------------
--(2) Desterrar del GY; barajar HASTA otras 3, robar 1
---------------------------------------------------

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    -- "except the turn it was sent there" (Evita usarlo el mismo turno que fue al GY)
    return e:GetHandler():GetTurnID()~=Duel.GetTurnCount()
end

function s.tdfilter(c)
    return c:IsSetCard(0x3fc) and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- "Up to 3" significa que el mínimo requerido para activar el efecto es ahora 1
        return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    -- Selecciona de 1 a 3 cartas del Cementerio (Mínimo: 1, Máximo: 3)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,3,nil)
    if #g>0 then
        Duel.HintSelection(g)
        -- Baraja las cartas en el Deck/Extra Deck
        if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
            -- Verifica que al menos una carta llegó correctamente al Deck/Extra antes de robar
            local og=Duel.GetOperatedGroup()
            if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
                Duel.BreakEffect() -- Separa el barajado del robo
                Duel.Draw(tp,1,REASON_EFFECT)
            end
        end
    end
end
