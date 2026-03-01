--Avatar Judgment
local s,id=GetID()

function s.initial_effect(c)
	-- Mention The Wicked Avatar
	aux.AddCodeList(c,21208154)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- Must control The Wicked Avatar
-------------------------------------------------
function s.avatarfilter(c)
	return c:IsFaceup() and c:IsCode(21208154)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil)
end

-------------------------------------------------
-- Activation
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local avatar=Duel.GetFirstMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,nil)
	if not avatar then return end

	local atk=avatar:GetAttack()

	local g=Duel.GetMatchingGroup(function(tc)
		return tc:IsFaceup()
			and tc:IsControler(1-tp)
			and tc:GetAttack()<atk
	end,tp,0,LOCATION_MZONE,nil)

	if #g==0 then return end

	-- Apply negation + material lock
	for tc in aux.Next(g) do
		tc:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)

		local e3=e1:Clone()
		e3:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
		e3:SetValue(1)
		tc:RegisterEffect(e3)

		local e4=e3:Clone()
		e4:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
		tc:RegisterEffect(e4)

		local e5=e3:Clone()
		e5:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
		tc:RegisterEffect(e5)

		local e6=e3:Clone()
		e6:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		tc:RegisterEffect(e6)
	end

	-------------------------------------------------
	-- End Phase destruction
	-------------------------------------------------
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_PHASE+PHASE_END)
	e7:SetCountLimit(1)
	e7:SetCondition(function(e,tp)
		return Duel.GetTurnPlayer()==tp
	end)
	e7:SetOperation(function(e,tp)
		local dg=Duel.GetMatchingGroup(function(tc)
			return tc:IsFaceup()
				and tc:IsControler(1-tp)
				and tc:GetFlagEffect(id)>0
		end,tp,0,LOCATION_MZONE,nil)

		if #dg==0 then return end

		if Duel.Destroy(dg,REASON_EFFECT)>0 then
			local codes={}
			for tc in aux.Next(dg) do
				local c1,c2=tc:GetOriginalCodeRule()
				codes[c1]=true
				if c2 then codes[c2]=true end
			end

			local e8=Effect.CreateEffect(e:GetHandler())
			e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e8:SetCode(EVENT_CHAIN_SOLVING)
			e8:SetCondition(function(_,tp,_,_,ev,re)
				if not re:IsMonsterEffect() then return false end
				local rc=re:GetHandler()
				if not rc:IsLocation(LOCATION_GRAVE) then return false end
				local c1,c2=rc:GetOriginalCodeRule()
				return codes[c1] or (c2 and codes[c2])
			end)
			e8:SetOperation(function(_,_,_,_,ev)
				Duel.NegateEffect(ev)
			end)
			e8:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
			Duel.RegisterEffect(e8,tp)
		end
	end)
	e7:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e7,tp)
end