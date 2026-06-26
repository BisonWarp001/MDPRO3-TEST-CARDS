--Sacrifices for the Evils
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,62180201,21208154,57793869)
    -- (1) Efecto de Invocación Especial (Quick-Play Spell)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMSUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Efecto enviado al Cementerio
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
end

-- Lista de IDs de los Wicked Gods
s.wicked_gods = {21208154, 62180201, 57793869}

function s.is_wicked(c)
    for _, wicked_id in ipairs(s.wicked_gods) do
        if c:IsCode(wicked_id) then return true end
    end
    return false
end

-- ==========================================
-- LOGICA EFECTO (1): INVOCACIÓN DESDE DECK/GY/MANO
-- ==========================================
function s.spfilter(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        -- Pide que haya cartas disponibles para desterrar en Mano, Deck o GY
        local g=Duel.GetMatchingGroup(Card.IsAbleToBanish,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil)
        return #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end
    if ft>3 then ft=3 end
    
    -- Seleccionar para desterrar (hasta 3 cartas)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToBanish,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,ft,nil)
    if #rg>0 and Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)>0 then
        local ct=rg:FilterCount(Card.IsLocation,nil,LOCATION_REMOVED)
        local count=Duel.GetLocationCount(tp,LOCATION_MZONE)
        if count>ct then count=ct end
        
        -- Invocar de modo Especial el mismo número desterrado
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,count,count,nil,e,tp)
        if #sg>0 then
            local tc=sg:GetFirst()
            for tc in aux.Next(sg) do
                Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
            end
            Duel.SpecialSummonComplete()
        end
    end
    
    -- Candado de Atributo: DARK
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,2)) -- "Can only Summon DARK monsters"
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_CANNOT_SUMMON)
    Duel.RegisterEffect(e2,tp)
    local e3=e1:Clone()
    e3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
    Duel.RegisterEffect(e3,tp)
end

function s.splimit(e,c)
    return not c:IsAttribute(ATTRIBUTE_DARK)
end

-- ==========================================
-- LOGICA EFECTO (2): EFECTO TIPO SOUL CROSSING (CORREGIDO)
-- ==========================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.thfilter(c,ec)
    if not s.is_wicked(c) then return false end
    if not c:IsAbleToHand() then return false end
    
    local e1=Effect.CreateEffect(ec)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_EXTRA_TRIBUTE)
    e1:SetRange(LOCATION_HAND)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetValue(POS_FACEUP_ATTACK+POS_FACEDOWN_DEFENSE)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
    
    local res=c:IsSummonable(true,nil,1)
    e1:Reset()
    return res
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e:GetHandler()) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,c)
    local tc=g:GetFirst()
    
    if tc and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
        Duel.ConfirmCards(1-tp,tc)
        Duel.ShuffleHand(tp)
        
        -- Habilitar tributos del oponente
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_ADD_EXTRA_TRIBUTE)
        e1:SetRange(LOCATION_HAND)
        e1:SetTargetRange(0,LOCATION_MZONE)
        e1:SetValue(POS_FACEUP_ATTACK+POS_FACEDOWN_DEFENSE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        -- Escuchar si la invocación tiene éxito para aplicar la restricción
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e2:SetCode(EVENT_SUMMON_SUCCESS)
        e2:SetReset(RESET_PHASE+PHASE_MAIN1+PHASE_MAIN2)
        e2:SetOperation(s.limitop)
        Duel.RegisterEffect(e2,tp)
        
        -- Resetear el escuchador si niegan la invocación
        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e3:SetCode(EVENT_SUMMON_NEGATED)
        e3:SetOperation(s.rstop)
        e3:SetLabelObject(e2)
        e3:SetReset(RESET_PHASE+PHASE_MAIN1+PHASE_MAIN2)
        Duel.RegisterEffect(e3,tp)
        
        -- Invocar inmediatamente
        Duel.Summon(tp,tc,true,nil,1)
    end
end

function s.cfilter(c,tp)
    return c:IsPreviousControler(1-tp)
end

function s.limitop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=eg:GetFirst()
    local g=tc:GetMaterial()
    
    -- Si se usó al menos un monstruo del oponente, aplicamos el candado dinámico de 2 turnos
    if g and g:IsExists(s.cfilter,1,nil,tp) then
        -- 1. Escuchador de cadenas que dura hasta el fin del PRÓXIMO turno (RESET_PHASE+PHASE_END,2)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_CHAINING)
        e1:SetReset(RESET_PHASE+PHASE_END,2) 
        e1:SetOperation(s.chaincountop)
        Duel.RegisterEffect(e1,tp)

        -- 2. El candado de activación que dura hasta el fin del PRÓXIMO turno (RESET_PHASE+PHASE_END,2)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
        e2:SetDescription(aux.Stringid(id,3)) -- "Solo puedes activar 1 efecto por turno (Excepto Wicked Gods)"
        e2:SetCode(EFFECT_CANNOT_ACTIVATE)
        e2:SetTargetRange(1,0)
        e2:SetCondition(s.actcon)
        e2:SetValue(s.aclimit)
        e2:SetReset(RESET_PHASE+PHASE_END,2) 
        Duel.RegisterEffect(e2,tp)
    end
    e:Reset()
end

function s.rstop(e,tp,eg,ep,ev,re,r,rp)
    local e1=e:GetLabelObject()
    if e1 then e1:Reset() end
    e:Reset()
end

-- Esta función registra un flag único para el turno actual usando Duel.GetTurnCount()
function s.chaincountop(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp and not (re:IsActiveType(TYPE_MONSTER) and s.is_wicked(re:GetHandler())) then
        -- Creamos una etiqueta numérica basada en el turno actual (ej: turno 1, turno 2)
        local turn=Duel.GetTurnCount()
        -- Registramos el flag acoplado al número de turno actual, durando 2 turnos en total
        Duel.RegisterFlagEffect(tp,id+turn,RESET_PHASE+PHASE_END,0,2)
    end
end

-- El candado verifica dinámicamente el flag del turno en curso
function s.actcon(e)
    local tp=e:GetHandlerPlayer()
    local turn=Duel.GetTurnCount()
    -- Lee estrictamente las activaciones que se han hecho EN ESTE TURNO específico
    return Duel.GetFlagEffect(tp,id+turn)>=1
end

-- Bloquea cualquier activación posterior a menos que sea un Wicked God
function s.aclimit(e,re,tp)
    return not (re:IsActiveType(TYPE_MONSTER) and s.is_wicked(re:GetHandler()))
end

