-- The Progenitor Gods' Pharaoh
local s,id=GetID()
s.listed_series={0x3f2}
function s.initial_effect(c)

	
	-------------------------------------------------
	-- (1) Reveal -> Search & Special Summon
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- (2) Triple Tribute (Estilo God Slime)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(id) -- ID único para el filtro de tributo
	c:RegisterEffect(e2)
	
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_HAND,0)
	e3:SetCondition(s.ttcon)
	e3:SetTarget(s.tttg)
	e3:SetOperation(s.ttop)
	e3:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e3)

	-------------------------------------------------
	-- (3) In Grave: Tribute -> Add to hand
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id+100)
	e4:SetCost(s.thcost)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

-- Lógica (1): Reveal -> Discard -> Search & Special Summon
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return not c:IsPublic() end
    -- Solo revelamos como costo
    Duel.ConfirmCards(1-tp,c)
end

function s.filter(c)
    return (c:IsRace(RACE_DIVINE) or c:IsSetCard(0x3f2)) 
        and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c) -- c es el Pharaoh revelado
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) 
    end
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- 1. Descartar 1 carta
    if Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD,c)==0 then return end
    
    -- 2. Añadir a la mano
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
        
        -- 3. Special Summon (si el Pharaoh sigue en mano)
        if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
            Duel.BreakEffect()
            Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end


-- Lógica (2) Triple Tribute
function s.ttfilter(c,tp)
	return c:IsHasEffect(id) and c:IsReleasable(REASON_SUMMON) and Duel.GetMZoneCount(tp,c)>0
end
function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc<=3 and Duel.IsExistingMatchingCard(s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.tttg(e,c)
	return c:IsRace(RACE_DIVINE)
end
function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

-- Lógica (3)

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.CheckReleaseGroup(tp,nil,1,nil) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectReleaseGroup(tp,nil,1,1,nil)
	Duel.Release(g,REASON_COST)
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