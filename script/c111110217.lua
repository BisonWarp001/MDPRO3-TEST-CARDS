-- The Great Leviathan of Orichalcos
local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Materiales de Fusión Generales: 5 Monstruos "Orichalcos"
    -- aux.AddFusionProcFunRep(c, filtro, cantidad, si_permite_mismo_material)
    aux.AddFusionProcFunRep(c,aux.FilterBoolFunction(Card.IsSetCard,0x3fc),5,true)

    -- INVOCACIÓN DE CONTACTO MODIFICADA: Barajar 5 cartas desde Campo o GY
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetRange(LOCATION_EXTRA)
    e2:SetCondition(s.hspcon)
    e2:SetTarget(s.hsptg)
    e2:SetOperation(s.hspop)
    c:RegisterEffect(e2)

    -- Inmunidad a efectos activados del oponente (Se mantiene intacto)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)

    -- (1) Quick Effect: Revelar cartas Orichalcos (Se mantiene intacto)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCost(s.atkcost)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)

    -- (2) EFECTO MODIFICADO: No activar S/T a menos que descarte una del mismo tipo
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_ACTIVATE_COST)
    e5:SetRange(LOCATION_MZONE)
    e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e5:SetTargetRange(0,1) -- Afecta solo al oponente
    e5:SetCondition(s.actcon)
    e5:SetTarget(s.acttg)
    e5:SetCost(s.actcost)
    e5:SetOperation(s.actop)
    c:RegisterEffect(e5)

    -- (3) Efecto Flotante estilo Miragejade (Se mantiene intacto)
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_REMOVE)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_LEAVE_FIELD)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCondition(s.descon)
    e6:SetOperation(s.desop)
    c:RegisterEffect(e6)
end

s.listed_series={0x3fc}

-------------------------------------------------------------------------------
-- NUEVA LÓGICA DE INVOCACIÓN POR CONTACTO (5 MONSTRUOS DESDE MZONE / GY)
-------------------------------------------------------------------------------
function s.hspfilter(c,tp)
    -- MODIFICACIÓN: c:IsMonster() garantiza que SOLO se elijan monstruos Orichalcos
    return c:IsSetCard(0x3fc) and c:IsMonster() 
        and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE)) 
        and c:IsAbleToDeckOrExtraAsCost()
end

function s.hspcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    -- Valida que haya espacio saliendo del Extra Deck (Evaluando zonas)
    local mzone_check = Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
    return mzone_check and Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,5,nil,tp)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    -- Selección exacta de los 5 materiales monstruo del Campo o GY
    local g=Duel.GetMatchingGroup(s.hspfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil,tp)
    if #g>=5 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local sg=g:Select(tp,5,5,nil)
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.HintSelection(g)
    -- Envía los 5 monstruos de vuelta al Deck barajándolo
    Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST+REASON_MATERIAL)
    c:SetMaterial(g)
    g:Delete()
end


-------------------------------------------------------------------------------
-- INMUNIDAD ESTÁNDAR
-------------------------------------------------------------------------------
function s.efilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

-------------------------------------------------------------------------------
-- (1) QUICK EFFECT: MANO (INTACTO)
-------------------------------------------------------------------------------
function s.cfilter(c)
    return c:IsSetCard(0x3fc) and not c:IsPublic()
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,63,nil)
    Duel.ConfirmCards(1-tp,g)
    Duel.ShuffleHand(tp)
    e:SetLabel(g:GetCount())
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetValue(e:GetLabel()*1000)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
end

-------------------------------------------------------------------------------
-- NUEVA LÓGICA EFECTO (2): COSTO DE ACTIVACIÓN FILTRADO POR MISMO TIPO
-------------------------------------------------------------------------------
function s.actcon(e)
    return Duel.GetAttacker()==e:GetHandler()
end

function s.acttg(e,te,tp)
    -- Detecta si lo que el rival quiere activar es una Magia o una Trampa
    return te:IsHasType(EFFECT_TYPE_ACTIVATE) and te:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

-- Filtro dinámico para comprobar el descarte
function s.dcfilter(c,type)
    return c:IsDiscardable() and c:IsType(type)
end

function s.actcost(e,te,tp,chk)
    -- Captura el tipo de la carta que el rival está intentando activar en la cadena
    local rtype = te:GetActiveType() & (TYPE_SPELL|TYPE_TRAP)
    if chk==0 then 
        -- Verifica si el oponente tiene en mano una carta que coincida con ese tipo exacto para descartar
        return Duel.IsExistingMatchingCard(s.dcfilter,tp,LOCATION_HAND,0,1,nil,rtype) 
    end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
    -- Fuerza el descarte correcto al oponente resolviendo la cadena
    local te=Duel.GetChainInfo(0,CHAININFO_TRIGGERING_EFFECT)
    local rtype = te:GetActiveType() & (TYPE_SPELL|TYPE_TRAP)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    Duel.DiscardHand(tp,s.dcfilter,1,1,REASON_COST+REASON_DISCARD,nil,rtype)
end

-------------------------------------------------------------------------------
-- (3) REPLICA MIRAGEJADE (INTACTO)
-------------------------------------------------------------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousControler(tp) and c:GetReasonPlayer()==1-tp
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_END)
    e1:SetCountLimit(1)
    e1:SetOperation(s.desop2)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.desop2(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    local g=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
end
