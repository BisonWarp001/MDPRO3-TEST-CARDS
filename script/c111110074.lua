-- The True Horror
-- ID sugerido: (Asegúrate de que coincida con tu base de datos)
local s,id=GetID()
function s.initial_effect(c)
    -- Mencionar a Dreadroot oficialmente
    aux.AddCodeList(c,62180201)
    
    -- EFECTO 1: Elección del oponente (Daño o Tributar)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DAMAGE+CATEGORY_RELEASE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- EFECTO 2: Cementerio (Búsqueda e Invocación Protegida)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

-- Condición: Controlar a The Wicked Dreadroot
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FilterFaceupFunction(Card.IsCode,62180201),tp,LOCATION_MZONE,0,1,nil)
end

-- Target: Previene que el oponente encadene efectos (Protección extra)
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    -- Bloquea respuestas del oponente a la activación de esta carta
    Duel.SetChainLimit(function(e,re,rp) return rp==tp end)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,4000)
end

-- Operación: La elección del oponente
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsReleasable,tp,0,LOCATION_MZONE,nil)
    local can_tribute = #g>=2
    local op=0
    
    if can_tribute then
        -- El oponente (1-tp) DEBE elegir en su pantalla
        -- Opción 0: Daño, Opción 1: Tributar
        op=Duel.SelectOption(1-tp, aux.Stringid(id,2), aux.Stringid(id,3))
    else
        -- Si no tiene 2 monstruos, el daño es automático
        op=0
    end
    
    if op==0 then
        Duel.Damage(1-tp,4000,REASON_EFFECT)
    else
        Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_RELEASE)
        local sg=g:Select(1-tp,2,2,nil)
        if #sg>0 then
            Duel.Release(sg,REASON_EFFECT)
        end
    end
end

-- Búsqueda e Invocación desde Cementerio
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,62180201) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,62180201)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        local tc=g:GetFirst()
        if tc:IsSummonable(true,nil) and Duel.SelectYesNo(tp, 1151) then
            -- 1. Invocación no puede ser negada
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD)
            e1:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
            e1:SetProperty(EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_SET_AVAILABLE)
            e1:SetTarget(function(e,c) return c:IsCode(62180201) end)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
            
            -- 2. El oponente no puede activar nada cuando entra al campo
            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e2:SetCode(EVENT_SUMMON_SUCCESS)
            e2:SetCondition(function(e,tp,eg) return eg:IsExists(Card.IsCode,1,nil,62180201) end)
            e2:SetOperation(function(e,tp) Duel.SetChainLimitTillChainEnd(function(e,re,rp) return rp==tp end) end)
            e2:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e2,tp)
            
            Duel.Summon(tp,tc,true,nil)
        end
    end
end
