--Nordic Relic Andvaranaut
local s,id=GetID()

s.listed_series={0x42,0x4b}

function s.initial_effect(c)

	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------
	--① Alternative Synchro
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.sccon)
	e1:SetTarget(s.sctg)
	e1:SetOperation(s.scop)
	c:RegisterEffect(e1)

	--------------------------------
	--② Banish & Destroy
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

------------------------------------------------
-- CONDITIONS
------------------------------------------------

function s.aesirfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x4b)
end

function s.sccon(e,tp)
	return not Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.descon(e,tp)
	return Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_MZONE,0,1,nil)
end

------------------------------------------------
-- MATERIAL FILTER
------------------------------------------------

function s.matfilter(c)
	return c:IsSetCard(0x42)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToRemove()
		and c:GetLevel()>0
end

------------------------------------------------
-- SYNCHRO VALIDATION (ENGINE-BASED)
------------------------------------------------

function s.syncheck(g,tp,sc)
	return sc:IsSynchroSummonable(nil,g,#g-1,#g-1)
end

function s.spfilter(c,tp,mg)
	if not c:IsSetCard(0x4b) or not c:IsType(TYPE_SYNCHRO) then return false end
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
		if not Duel.IsPlayerCanSpecialSummon(tp) then return false end
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

------------------------------------------------
-- OPERATION
------------------------------------------------

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,tp,mg)
	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,1,1,nil)
	local sc=sg:GetFirst()

	aux.GCheckAdditional=aux.SynGroupCheckLevelAddition(sc)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local mat=mg:SelectSubGroup(tp,s.syncheck,false,2,3,tp,sc)
	aux.GCheckAdditional=nil
	if not mat then return end

	-- Banish materials
	if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO)==0 then return end
	Duel.BreakEffect()

	-- Proper Synchro treatment
	sc:SetMaterial(mat)
	if Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end

------------------------------------------------
-- SECOND EFFECT
------------------------------------------------

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsAbleToRemove()
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.Remove(c,POS_FACEUP,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end