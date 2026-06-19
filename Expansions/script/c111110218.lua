-- Orichalcos Dimensional Shield
-- ID sugerido: Cambia 'id' por el número que uses en tu base de datos (ej. 111110213)
local s,id=GetID()
function s.initial_effect(c)
    -- Activar Carta (Trampa Continua)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    -- You can only control 1 "Orichalcos Dimensional Shield".
    c:SetUniqueOnField(1,0,id)

    -- (1) Neither player can Special Summon from the Extra Deck unless they pay 1000 LP for each.
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(1,1) -- Afecta a ambos jugadores
    e2:SetTarget(s.splimit)
    c:RegisterEffect(e2)

    -- Registro continuo para cobrar los LP al resolver cualquier Invocación Especial
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetRange(LOCATION_SZONE)
    e3:SetOperation(s.payop)
    c:RegisterEffect(e3)

    -- (2) If this card is in your GY: Banish this card; Place 1 "Orichalcos Dimensional Shield" face-up from your Deck to your Spell/Trap Zone.
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCost(aux.bfgcost) -- Destierra esta carta automáticamente como costo
    e4:SetTarget(s.tfptg)
    e4:SetOperation(s.tfpop)
    c:RegisterEffect(e4)
end

-- 1. Lógica de Restricción e Invocación (Estilo Vanity's Fiend)
function s.splimit(e,c,tp,sumtp,sumpos,target_tp)
    if c:IsLocation(LOCATION_EXTRA) then
        return not Duel.CheckLPCost(target_tp,1000)
    end
    return false
end

-- Deducción de los 1000 LP por cada monstruo invocado con éxito del Extra Deck
function s.payfilter(c)
    return c:IsLocation(LOCATION_MZONE) and c:GetSummonLocation()==LOCATION_EXTRA
end
function s.payop(e,tp,eg,ep,ev,re,r,rp)
    local g=eg:Filter(s.payfilter,nil)
    if #g>0 then
        local players={}
        for tc in aux.Next(g) do
            players[tc:GetSummonPlayer()]=true
        end
        for p,v in pairs(players) do
            local count=g:FilterCount(Card.IsSummonPlayer,nil,p)
            Duel.PayLPCost(p,count*1000)
        end
    end
end

-- 2. Lógica de colocación adaptada al estilo oficial de "Maiden of White"
function s.tfpfilter(c,tp)
    return c:IsCode(id) and c:IsType(TYPE_TRAP)
        and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

function s.tfptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.tfpfilter,tp,LOCATION_DECK,0,1,nil,tp) 
    end
end

function s.tfpop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.tfpfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
    if tc then 
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) 
    end
end
