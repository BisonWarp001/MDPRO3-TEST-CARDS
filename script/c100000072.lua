--Inevitable End
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,57793869)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--GY effect
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

--Control Eraser
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(57793869)
end

--Negate condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Target
function s.spfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,1-tp,false,false)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,1-tp,LOCATION_GRAVE)
end

--Operation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local g=Duel.GetMatchingGroup(s.spfilter,tp,0,LOCATION_GRAVE,nil,e,tp)
		if #g>0 then
			local sg=g:Select(tp,1,2,nil)
			if #sg>0 then
				for tc in aux.Next(sg) do
					if Duel.SpecialSummonStep(tc,0,tp,1-tp,false,false,POS_FACEUP) then
						--Negate effects
						local e1=Effect.CreateEffect(e:GetHandler())
						e1:SetType(EFFECT_TYPE_SINGLE)
						e1:SetCode(EFFECT_DISABLE)
						e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
						tc:RegisterEffect(e1)

						local e2=e1:Clone()
						e2:SetCode(EFFECT_DISABLE_EFFECT)
						tc:RegisterEffect(e2)
					end
				end
				Duel.SpecialSummonComplete()
			end
		end
	end
end

--GY destroy
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end