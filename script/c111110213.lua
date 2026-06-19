-- Orichalcos Malevolence - Demon of Fire
local s,id=GetID()
function s.initial_effect(c)
    -- 1. Negar efectos e Invocar Especialmente (Efecto de Encendido)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- 2. Sustitución de destrucción (Efecto Continuo)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
end

-- Lógica de Invocación Especial y Negación
function s.disfilter(c)
    return c:IsFaceup() and not c:IsDisabled()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.disfilter(chkc) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingTarget(s.disfilter,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.disfilter,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    -- Validar que el objetivo sigue en el campo y es válido
    if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
        -- Aplicar negación de efectos
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        
        -- Si la negación se aplicó con éxito, invocar (Equivale al "and if you do")
        if not tc:IsImmuneToEffect(e1) and not tc:IsImmuneToEffect(e2) then
            Duel.AdjustInstantly(tc)
            if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
                Duel.BreakEffectRow() -- Establece la ventana de tiempo para el "and if you do"
                Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
            end
        end
    end
end

-- Lógica de protección por sustitución "Orichalcos" (0x3fc)
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD)
        and c:IsSetCard(0x3fc) and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    -- Debe ser destruido por un efecto de carta del oponente
    if not re or rp==tp or not (r&REASON_EFFECT==REASON_EFFECT) then return false end
    if chk==0 then return c:IsAbleToRemove() and not c:IsStatus(STATUS_DESTROY_CONFIRMED)
        and eg:IsExists(s.repfilter,1,nil,tp) end
    return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end
