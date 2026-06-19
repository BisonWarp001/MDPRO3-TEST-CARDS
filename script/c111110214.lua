-- Orichalcos Deuteros - Legacy of the Darkness
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,111110210)
    -- Activar Carta
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    -- Solo puedes controlar 1
    c:SetUniqueOnField(1,0,id)

    -- PROTECCIÓN: Mientras controlas "Forbidden Seal of Orichalcos", tus Magias/Trampas Orichalcos no pueden ser destruidas
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_INDESTRUCTIBLE_EFFECT)
    e0:SetRange(LOCATION_SZONE)
    e0:SetTargetRange(LOCATION_SZONE,0) -- Protege tus Magias/Trampas
    e0:SetCondition(s.protcon)
    e0:SetTarget(s.prottg)
    e0:SetValue(s.indval)
    c:RegisterEffect(e0)

    -- (1) Once per turn: You can add 1 "Orichalcos" Spell/Trap from your Deck to your hand.
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- (2) If this card is in your GY: You can banish it; Place 1 "Forbidden Seal of Orichalcos" face-up on your Field Zone from your Deck or GY.
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCost(aux.bfgcost) -- Costo: Desterrarse a sí misma
    e3:SetTarget(s.tfptg)
    e3:SetOperation(s.tfpop)
    c:RegisterEffect(e3)
end

-- Lógica de la condición de protección 
function s.cfilter(c)
    return c:IsFaceup() and c:IsCode(111110210)
end
function s.protcon(e)
    return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_FZONE,0,1,nil)
end
-- Solo protege a cartas con el setcode 0x3fc que sean Magias o Trampas
function s.prottg(e,c)
    return c:IsSetCard(0x3fc) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.indval(e,re,rp)
    return rp~=e:GetHandlerPlayer() -- Solo protege contra efectos del oponente
end

-- 1. Lógica del efecto de búsqueda (Magia/Trampa Arquetipo 0x3fc)
function s.thfilter(c)
    return c:IsSetCard(0x3fc) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- 2. Lógica para colocar Forbidden Seal of Orichalcos desde el Deck o GY
function s.tfpfilter(c,tp)
    return c:IsCode(111110210) and c:IsType(TYPE_FIELD) and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.tfptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tfpfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp) end
end
function s.tfpop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.tfpfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp)
    local tc=g:GetFirst()
    if tc then
        local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
        if fc then
            Duel.SendtoGrave(fc,REASON_RULE)
        end
        Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
        local te=tc:GetActivateEffect()
        local tep=tc:GetControler()
        local cost=te:GetCost()
        if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
        Duel.RaiseEvent(tc,EVENT_CHAIN_SOLVED,te,0,tp,tp,Duel.GetCurrentChain())
    end
end
