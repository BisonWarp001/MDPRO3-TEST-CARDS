-- Dark Summoning Ritual

local s,id=GetID()
function s.initial_effect(c)

	-- Activate (Ritual Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Grave Effect (Ritual Summon)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.ritualcond)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.ritualtg)
	e2:SetOperation(s.ritualop)
	c:RegisterEffect(e2)
end

-- Filter to Special Summon from Deck
function s.rfilter1(c,e,tp)
	return c:IsCode(130000511)
end

function s.rfilter2(c,e,tp)
	return bit.band(c:GetType(),0x81)==0x81 and c:IsCode(130000511) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.cfilter(c,e,tp)
	return c:IsFaceup() and not c:IsImmuneToEffect(e) and c:IsControler(tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg1=Duel.GetRitualMaterial(tp)
		local mg2=Duel.GetReleaseGroup(1-tp,false,REASON_EFFECT):Filter(s.cfilter,nil,e,1-tp)
		return Duel.IsExistingMatchingCard(aux.RitualUltimateFilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,s.rfilter1,e,tp,mg1,nil,Card.GetLevel,"Equal")
			or (mg2:GetCount()>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and Duel.IsExistingMatchingCard(s.rfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp))
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	::cancel::
	local mg1=Duel.GetRitualMaterial(tp)
	local mg2=Duel.GetReleaseGroup(1-tp,false,REASON_EFFECT):Filter(s.cfilter,nil,e,1-tp)
	local g1=Duel.GetMatchingGroup(aux.RitualUltimateFilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil,s.rfilter1,e,tp,mg1,nil,Card.GetLevel,"Equal")
	local g2=nil
	local g=g1
	if mg2:GetCount()>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		g2=Duel.GetMatchingGroup(s.rfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,tp)
		g=g1+g2
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if tc then
		local mg=mg1:Filter(Card.IsCanBeRitualMaterial,tc,tc)
		if tc.mat_filter then
			mg=mg:Filter(tc.mat_filter,tc,tp)
		else
			mg:RemoveCard(tc)
		end
		if g1:IsContains(tc) and (not g2 or (g2:IsContains(tc) and not Duel.SelectYesNo(tp,aux.Stringid(id,0)))) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			aux.GCheckAdditional=aux.RitualCheckAdditional(tc,tc:GetLevel(),"Equal")
			local mat=mg:SelectSubGroup(tp,aux.RitualCheck,true,1,tc:GetLevel(),tp,tc,tc:GetLevel(),"Equal")
			aux.GCheckAdditional=nil
			if not mat then goto cancel end
			tc:SetMaterial(mat)
			Duel.ReleaseRitualMaterial(mat)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			local matc=mg2:SelectUnselect(nil,tp,false,true,1,1)
			if not matc then goto cancel end
			local mat=Group.FromCards(matc)
			tc:SetMaterial(mat)
			Duel.ReleaseRitualMaterial(mat)
		end
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			Duel.SetLP(tp,Duel.GetLP(tp)-tc:GetBaseAttack())
			tc:CompleteProcedure()
		end
	end
end

-- Effect ②: Condition to check if a DARK Ritual Monster was destroyed by opponent's card effect
function s.plcfilter(c,tp)
	return c:IsType(TYPE_RITUAL) and c:IsPreviousControler(tp)
		and c:IsAttribute(ATTRIBUTE_DARK) and c:GetPreviousAttributeOnField()&ATTRIBUTE_DARK>0
		and c:IsPreviousPosition(POS_FACEUP) and c:GetReasonPlayer()==1-tp
		and c:IsReason(REASON_EFFECT) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.ritualcond(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.plcfilter,1,nil,tp)
end

-- Special Summon "Great Magus" or "Zorc Necrophades"
function s.filter(c,e,tp)
	return c:IsCode(130000510,130000511) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

-- Target to Special Summon
function s.ritualtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- Special Summon from hand or Deck
function s.ritualop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,1,nil,e,tp)
	if g:GetCount()>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end