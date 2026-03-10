--Shadow Torment - Imprisoning Chains of Torment
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	aux.AddXyzProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x406),4,2)
	c:EnableReviveLimit()
	
	--Disable + restriction effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--Detach 2 Xyz materials
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

--Target filter
function s.filter(c)
	return c:IsFaceup() or c:IsType(TYPE_SPELL+TYPE_TRAP)
end

--Target up to 3 opponent cards
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_ONFIELD,1,3,nil)
end

--Apply restrictions
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if not c:IsFaceup() or #g==0 then return end

	for tc in aux.Next(g) do
		if tc:IsRelateToEffect(e) then

			--negate effects
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)

			if tc:IsType(TYPE_MONSTER) then

				--cannot attack
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_CANNOT_ATTACK)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e3)

				--cannot be Fusion material
				local e4=Effect.CreateEffect(c)
				e4:SetType(EFFECT_TYPE_SINGLE)
				e4:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
				e4:SetValue(1)
				e4:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e4)

				--cannot be Synchro material
				local e5=e4:Clone()
				e5:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
				tc:RegisterEffect(e5)

				--cannot be Xyz material
				local e6=e4:Clone()
				e6:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
				tc:RegisterEffect(e6)

				--cannot be Link material
				local e7=e4:Clone()
				e7:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
				tc:RegisterEffect(e7)

			end
		end
	end
end