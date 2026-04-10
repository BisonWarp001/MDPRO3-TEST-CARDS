-- Oath of the Three Gods TERMINADO
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,10000000,10000010,10000020)
	--(1) Negate activation, destroy it
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_TOGRAVE+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--====================================
-- Filters
--====================================
-- For effect (1): any Divine-Beast
function s.dbfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DIVINE)
end

-- For effect (2): only original Egyptian Gods
function s.godfilter(c)
	return c:IsFaceup() and c:IsCode(10000000,10000010,10000020)
end

--====================================
-- Condition
--====================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.dbfilter,tp,LOCATION_MZONE,0,1,nil)
end

--====================================
-- Target
--====================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)

	local rc=re:GetHandler()
	if rc and rc:IsRelateToEffect(re) and rc:IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
	end

	-- Optional extra effect preview
	if Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_EXTRA,0,1,nil)
		and Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
		Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,1-tp,LOCATION_HAND)
	end
end

--====================================
-- Operation
--====================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	-- Negate + destroy
	if Duel.NegateActivation(ev) then
		if rc and rc:IsRelateToEffect(re) then
			Duel.Destroy(rc,REASON_EFFECT)
		end

		-- Extra effect ONLY with Obelisk / Ra / Slifer
		if Duel.IsExistingMatchingCard(s.godfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_EXTRA,0,1,nil)
			and Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then

			if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				Duel.BreakEffect()

				-- Send 1 from Extra Deck to GY
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,LOCATION_EXTRA,0,1,1,nil)
				if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
					-- Random opponent hand card to GY
					local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
					if #hg>0 then
						Duel.BreakEffect()
						local sg=hg:RandomSelect(tp,1)
						Duel.SendtoGrave(sg,REASON_EFFECT)
					end
				end
			end
		end
	end
end