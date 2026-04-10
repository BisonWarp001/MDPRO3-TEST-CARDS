--The Evil Shapeshifter
local s,id=GetID()

function s.initial_effect(c)
	-- Code list (The Wicked Avatar)
	aux.AddCodeList(c,21208154,62180201,57793869)

	-------------------------------------------------
	-- ① Activate: Add Avatar + Extra Tribute Summon (OATH)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY: Banish; Opponent's Set S/T cannot be activated
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.stop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Search The Wicked Gods (The 3 of them)
-------------------------------------------------
function s.thfilter(c,code)
    return c:IsCode(code) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- Verifica que al menos uno de los 3 esté disponible
        return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,21208154,62180201,57793869)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local codes={21208154,62180201,57793869}
    local sg=Group.CreateGroup()
    
    for _,code in ipairs(codes) do
        local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,code)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local tc=g:Select(tp,1,1,nil):GetFirst()
            sg:AddCard(tc)
        end
    end
    
    if #sg>0 then
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
        
        -------------------------------------------------
        -- Extra Tribute Summon (Solo si añadiste cartas)
        -------------------------------------------------
        if Duel.GetFlagEffect(tp,78665705)~=0 then return end
        if not (Duel.IsPlayerCanSummon(tp) and Duel.IsPlayerCanAdditionalSummon(tp)) then return end

        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
        e1:SetTargetRange(LOCATION_HAND,0)
        e1:SetTarget(aux.TargetBoolFunction(Card.IsLevelAbove,5))
        e1:SetValue(0x1)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)

        local e2=e1:Clone()
        e2:SetCode(EFFECT_EXTRA_SET_COUNT)
        Duel.RegisterEffect(e2,tp)

        Duel.RegisterFlagEffect(tp,78665705,RESET_PHASE+PHASE_END,0,1)
    end
end



-------------------------------------------------
-- GY Effect: Tribute Summon cannot be negated
-------------------------------------------------
function s.stop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- No se puede negar la Invocación (Normal/Sacrificio)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e1:SetProperty(EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetTargetRange(1,0) -- Solo al jugador que activó el efecto
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- Opcional: Impedir que el oponente active cartas en respuesta a la invocación
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetTargetRange(0,1)
	e3:SetValue(s.aclimit)
	e3:SetCondition(s.actcon)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

-- Filtro para que el oponente no responda a la invocación (estilo Hot Spring)
function s.actcon(e)
	return Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end

function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER)
end
