-- Orichalcos Shunoros - The Machine of Destruction
local s,id=GetID()

function s.initial_effect(c)
    -- Registro de que esta carta menciona exclusivamente a Divine Serpent Geh (82103466)
    aux.AddCodeList(c,82103466)
    
    -- Debe ser invocado por efectos (Condición de monstruo Nomi/Special Summon Only)
    c:EnableReviveLimit()
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e0)

    -- Restricción de Invocación Normal / Colocar (Set)
    local e00=Effect.CreateEffect(c)
    e00:SetType(EFFECT_TYPE_SINGLE)
    e00:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e00:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e00)
    local e00b=e00:Clone()
    e00b:SetCode(EFFECT_CANNOT_MSET)
    c:RegisterEffect(e00b)

    -- INMUNIDAD: No puede ser seleccionado (targeted) por efectos de cartas del oponente
    local e_target=Effect.CreateEffect(c)
    e_target:SetType(EFFECT_TYPE_SINGLE)
    e_target:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e_target:SetRange(LOCATION_MZONE)
    e_target:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e_target:SetValue(aux.tgoval) -- Filtro estándar que evalúa si la carta es del oponente
    c:RegisterEffect(e_target)

    -- (1) Trigger Hand: Invocar de Modo Especial si un monstruo propio es destruido
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_DESTROYED)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (2) Quick Effect: Ganar ATK igual a tus LP durante el cálculo de daño (Hasta la End Phase)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.atkcon)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)

    -- (3) Ignition Effect: Añadir 1 "Divine Serpent Geh" de Deck o GY a la mano
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+200)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)

    -- (4) Trigger Field/GY: Si es destruido, invoca a Geh (Hand/Deck/GY) ignorando condiciones
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCountLimit(1,id+300)
    e4:SetCondition(s.gehspcon)
    e4:SetTarget(s.gehsptg)
    e4:SetOperation(s.gehspop)
    c:RegisterEffect(e4)
end

-------------------------------------------------------------------------------
-- LOGICA EFECTO (1): INVOCACIÓN DESDE MANO AL SER DESTRUIDO UN ALIADO
-------------------------------------------------------------------------------
function s.cfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and ((c:IsReason(REASON_BATTLE) and Duel.GetAttacker() and Duel.GetAttacker():IsControler(1-tp))
        or (c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp))
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)~=0 then
        c:CompleteProcedure()
    end
end

-------------------------------------------------------------------------------
-- LOGICA EFECTO (2): GANANCIA DE ATK IGUAL A LP (HASTA END PHASE)
-------------------------------------------------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c==Duel.GetAttacker() or c==Duel.GetAttackTarget()
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(Duel.GetLP(tp))
        -- RESET_PHASE + PHASE_END asegura que el ATK se limpie al terminar el turno
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e1)
    end
end

-------------------------------------------------------------------------------
-- LOGICA EFECTO (3): BUSCADOR DE DIVINE SERPENT GEH
-------------------------------------------------------------------------------
function s.thfilter(c)
    return c:IsCode(82103466) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-------------------------------------------------------------------------------
-- LOGICA EFECTO (4): FLOTACIÓN AL MORIR (INVOCAR A GEH IGNORANDO RESTRICCIONES)
-------------------------------------------------------------------------------
-- Verifica que haya sido destruido por una batalla o por efecto de carta del oponente
function s.gehspcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_BATTLE) or (c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT))
end
-- Filtro para comprobar si Geh está en mano, mazo o cementerio
function s.gehfilter(c,e,tp)
    return c:IsCode(82103466)
end
function s.gehsptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.gehfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.gehspop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    -- Permite seleccionar a Geh desde la mano, el mazo o el cementerio
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.gehfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    local tc=g:GetFirst()
    if tc then
        -- El primer booleano 'true' salta olímpicamente el candado "Must be Special Summoned by..." de Geh
        if Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)~=0 then
            tc:CompleteProcedure()
        end
    end
end
