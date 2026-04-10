-- Offering to the Heavenly God Cult
local s,id=GetID()

function s.initial_effect(c)
    -- Activar
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Filtro: Monstruos que no sean el que va a ganar ATK y que puedan ser tributados
function s.atkfilter(c,tp)
    return (c:IsControler(tp) or c:IsFaceup()) and c:IsReleasableByEffect()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    -- Necesitas al menos 1 Divine-Beast en campo para activar
    if chk==0 then return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_DIVINE),tp,LOCATION_MZONE,0,1,nil) end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    
    -- 1. Seleccionar a qué Divine-Beast potenciar
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectMatchingCard(tp,aux.FaceupFilter(Card.IsRace,RACE_DIVINE),tp,LOCATION_MZONE,0,1,1,nil)
    local tc=g:GetFirst()
    
    if tc then
        Duel.HintSelection(g)
        
        -- 2. Seleccionar monstruos para tributar (como coste de la operación)
        local sg=Duel.GetReleaseGroup(tp):Filter(s.atkfilter,tc,tp)
        if #sg>0 and Duel.SelectYesNo(tp, aux.Stringid(id,0)) then -- ¿Quieres tributar?
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
            local rg=sg:Select(tp,1,sg:GetCount(),nil)
            local ct=#rg
            
            -- Calcular ATK (puedes usar GetAttack o 1000 por cada uno como pediste)
            -- Según tu descripción original: 1000 por cada monstruo tributado
            local atk_gain = ct * 1000
            
            Duel.Release(rg,REASON_COST)
            
            -- Aplicar ATK al Divine-Beast seleccionado
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(atk_gain)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
            
            -- 3. Si tributaste 3 o más, negar oponentes
            if ct>=3 then
                local og=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
                if #og>0 then
                    Duel.BreakEffect()
                    for oc in aux.Next(og) do
                        local e2=Effect.CreateEffect(c)
                        e2:SetType(EFFECT_TYPE_SINGLE)
                        e2:SetCode(EFFECT_DISABLE)
                        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                        oc:RegisterEffect(e2)
                        local e3=Effect.CreateEffect(c)
                        e3:SetType(EFFECT_TYPE_SINGLE)
                        e3:SetCode(EFFECT_DISABLE_EFFECT)
                        e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                        oc:RegisterEffect(e3)
                    end
                end
            end
        end
    end
end
