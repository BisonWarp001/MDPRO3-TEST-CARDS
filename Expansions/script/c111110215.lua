-- The Orichalcos Choice
-- ID sugerido: Cambia 'id' por el número que uses en tu base de datos (ej. 48179396)
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,111110210)
    -- Activar Carta (Trampa Continua)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- Auto-destrucción si no controlas "Forbidden Seal of Orichalcos"
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCode(EFFECT_SELF_DESTROY)
    e2:SetCondition(s.descon)
    c:RegisterEffect(e2)

    -- Una vez por turno (EFECTO RÁPIDO): Elegir 1 de los dos efectos aplicables
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_QUICK_O) -- Cambiado a Efecto Rápido
    e3:SetCode(EVENT_FREE_CHAIN)     -- Permite encadenarlo de forma libre
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.choicetg)
    e3:SetOperation(s.choiceop)
    c:RegisterEffect(e3)

    -- Efecto Continuo 1: Infligir 300 de daño por cada efecto de monstruo del oponente
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_CHAIN_SOLVING)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCondition(s.damcon)
    e4:SetOperation(s.damop)
    c:RegisterEffect(e4)

    -- Efecto Continuo 2: Ganar 300 LP por cada efecto de monstruo del oponente
    local e5=e4:Clone()
    e5:SetCondition(s.lpcon)
    e5:SetOperation(s.lpop)
    c:RegisterEffect(e5)
end

-- Condición de auto-destrucción (Sincronizado con tu ID 111110210)
function s.desfilter(c)
    return c:IsFaceup() and c:IsCode(111110210)
end
function s.descon(e)
    return not Duel.IsExistingMatchingCard(s.desfilter,e:GetHandlerPlayer(),LOCATION_FZONE,0,1,nil)
end

-- El Target despliega el menú en velocidad de Trampa
function s.choicetg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
    e:SetLabel(op)
end

-- La Operación aplica el Flag seleccionado de forma inmediata
function s.choiceop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local op=e:GetLabel()
    
    -- Limpiar flags previos para el cambio de turno
    c:ResetFlagEffect(id)
    
    if op==0 then
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,1)
    else
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,2)
    end
end

-- Lógica para infligir daño (Filtra la etiqueta '1')
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return re:IsActiveType(TYPE_MONSTER) and rp==1-tp 
        and c:GetFlagEffectLabel(id)==1
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.Damage(1-tp,300,REASON_EFFECT)
end

-- Lógica para ganar LP (Filtra la etiqueta '2')
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return re:IsActiveType(TYPE_MONSTER) and rp==1-tp 
        and c:GetFlagEffectLabel(id)==2
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.Recover(tp,500,REASON_EFFECT)
end
