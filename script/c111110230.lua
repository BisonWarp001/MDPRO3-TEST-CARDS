```lua
-- Nordic Castle of Asgard's Realm
local s,id=GetID()

s.listed_series={0x42,0x4b}

function s.initial_effect(c)

    -- Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    ------------------------------------------------
    -- (1) Alternative Synchro Summon
    ------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sctg)
    e1:SetOperation(s.scop)
    c:RegisterEffect(e1)

    ------------------------------------------------
    -- (2) Banish this card; shuffle 1 banished Aesir
    ------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.tdtg)
    e2:SetOperation(s.tdop)
    c:RegisterEffect(e2)
end

------------------------------------------------
-- MATERIAL FILTER
------------------------------------------------

function s.matfilter(c)
    return c:IsSetCard(0x42)
        and c:IsType(TYPE_MONSTER)
        and c:IsAbleToDeck()
        and c:GetLevel()>0
        and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

------------------------------------------------
-- SYNCHRO VALIDATION (ENGINE-BASED)
------------------------------------------------

function s.syncheck(g,tp,sc)
    return sc:IsSynchroSummonable(nil,g,#g-1,#g-1)
end

function s.spfilter(c,tp,mg)
    if not c:IsSetCard(0x4b) or not c:IsType(TYPE_SYNCHRO) then
        return false
    end
    aux.GCheckAdditional=aux.SynGroupCheckLevelAddition(c)
    local res=mg:CheckSubGroup(s.syncheck,2,99,tp,c)
    aux.GCheckAdditional=nil
    return res
end

------------------------------------------------
-- TARGET
------------------------------------------------

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        if not Duel.IsPlayerCanSpecialSummon(tp) then
            return false
        end

        local mg=Duel.GetMatchingGroup(
            s.matfilter,tp,
            LOCATION_GRAVE+LOCATION_REMOVED,
            0,nil
        )

        return Duel.IsExistingMatchingCard(
            s.spfilter,tp,
            LOCATION_EXTRA,0,1,nil,tp,mg
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TODECK,
        nil,1,tp,
        LOCATION_GRAVE+LOCATION_REMOVED
    )

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,
        LOCATION_EXTRA
    )
end

------------------------------------------------
-- OPERATION
------------------------------------------------

function s.scop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsLocation(LOCATION_SZONE) then
        return
    end

    local mg=Duel.GetMatchingGroup(
        s.matfilter,tp,
        LOCATION_GRAVE+LOCATION_REMOVED,
        0,nil
    )

    local g=Duel.GetMatchingGroup(
        s.spfilter,tp,
        LOCATION_EXTRA,
        0,nil,tp,mg
    )

    if #g==0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=g:Select(tp,1,1,nil)
    local sc=sg:GetFirst()

    aux.GCheckAdditional=aux.SynGroupCheckLevelAddition(sc)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local mat=mg:SelectSubGroup(
        tp,s.syncheck,false,
        2,99,tp,sc
    )

    aux.GCheckAdditional=nil

    if not mat then
        return
    end

    sc:SetMaterial(mat)

    if Duel.SendtoDeck(
        mat,nil,SEQ_DECKSHUFFLE,
        REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO
    )==0 then
        return
    end

    Duel.BreakEffect()

    if Duel.SpecialSummon(
        sc,SUMMON_TYPE_SYNCHRO,
        tp,tp,false,false,
        POS_FACEUP
    )>0 then

        sc:CompleteProcedure()

        -- Restricción hasta el final del próximo turno
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_CANNOT_ACTIVATE)
        e1:SetTargetRange(1,0)
        e1:SetValue(s.actlimit)
        e1:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e1,tp)
    end
end

------------------------------------------------
-- ACTIVATION RESTRICTION
------------------------------------------------

function s.actlimit(e,re,tp)
    local rc=re:GetHandler()
    return rc:IsLocation(LOCATION_MZONE)
        and rc:GetPreviousLocation()==LOCATION_EXTRA
        and not rc:IsSetCard(0x4b)
end

------------------------------------------------
-- EFFECT (2)
------------------------------------------------

function s.tdfilter(c)
    return c:IsSetCard(0x4b)
        and c:IsFaceup()
        and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.tdfilter,tp,
            LOCATION_REMOVED,0,1,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TODECK,
        nil,1,tp,
        LOCATION_REMOVED
    )
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)

    local g=Duel.SelectMatchingCard(
        tp,s.tdfilter,tp,
        LOCATION_REMOVED,0,
        1,1,nil
    )

    if #g>0 then
        Duel.SendtoDeck(
            g,nil,SEQ_DECKSHUFFLE,
            REASON_EFFECT
        )
    end
end
```
