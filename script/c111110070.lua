-- Advent of the Evil Deities
local s,id=GetID()
function s.initial_effect(c)
    -- Mencionar cartas para MDPro3
    aux.AddCodeList(c,21208154,62180201,57793869)
    
    -- ① Activar la carta (Poner boca arriba)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- ② Efecto de los Tokens (Modificado para forzar la revelación)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ③ Reciclaje (Trigger en GY)
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

-- Filtro de los Dioses
function s.revealfilter(c)
    return c:IsCode(21208154,62180201,57793869) and not c:IsPublic()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_HAND,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.revealfilter,tp,LOCATION_HAND,0,nil)
    if #g==0 then return end
    
    -- Forzar selección manual de hasta 3 nombres distintos
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local rg=g:Select(tp,1,3,nil)
    
    -- Validar nombres distintos manualmente para evitar errores de aux.dncheck
    local check=0
    local codes={}
    local final_g=Group.CreateGroup()
    for tc in aux.Next(rg) do
        local code=tc:GetCode()
        if not codes[code] then
            codes[code]=true
            final_g:AddCard(tc)
        end
    end

    if #final_g>0 then
        Duel.ConfirmCards(1-tp,final_g)
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        local ct=math.min(#final_g,ft)
        if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ct=1 end
        
        for i=1,ct do
            local token=Duel.CreateToken(tp,111110077)
            Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
        end
    end
    
    -- Bloqueo del Extra Deck
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
    return c:IsLocation(LOCATION_EXTRA)
end

-- Lógica de Reciclaje
function s.cfilter(c,tp)
    return c:IsCode(21208154, 62180201, 57793869) and c:IsControler(tp)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end
