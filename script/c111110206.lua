-- Authority of Gods
local s,id=GetID()

function s.initial_effect(c)
	-- Registro de los 3 Dioses (IDs: 200, 201, 202)
	aux.AddCodeList(c,111110200,111110201,111110202)

	-------------------------------------------------
	-- ① Activate: Add 3 Divine-Beasts + Discard 2 + Extra Tribute
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② GY: Banish to add 1 banished Divine-Beast/Mention
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(aux.exccon) -- No el turno que fue enviada
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- ① Lógica de Búsqueda (Estilo Sacred Beast)
-------------------------------------------------
function s.filter(c)
    return c:IsRace(RACE_DIVINE) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
        return g:GetClassCount(Card.GetCode)>=3 
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,3,tp,LOCATION_DECK+LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,2)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
    if g:GetClassCount(Card.GetCode)<3 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    -- SelectSubGroup con aux.dncheck garantiza 3 nombres diferentes
    local sg=g:SelectSubGroup(tp,aux.dncheck,false,3,3)
    
    if sg and #sg==3 then
        if Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,sg)
            Duel.ShuffleHand(tp)
            Duel.BreakEffect()
            
            -- Descartar 2
            local dg=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,2,2,nil)
            if #dg==2 and Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)>0 then
                -- Aplicar Invocación por Sacrificio Adicional
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_FIELD)
                e1:SetTargetRange(LOCATION_HAND,0)
                e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
                e1:SetValue(0x1)
                e1:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e1,tp)
            end
        end
    end
end

-------------------------------------------------
-- ② Lógica de Reciclaje desde el Destierro
-------------------------------------------------
function s.recfilter(c)
	return c:IsFaceup() and c:IsAbleToHand() and (
		c:IsRace(RACE_DIVINE) or 
		c:ListsCode(111110200, 111110201, 111110202)
	)
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.recfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.recfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
