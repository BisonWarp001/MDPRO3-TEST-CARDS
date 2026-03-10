--Shadow Torment - Revival Jam the Eternal Slime
local s,id=GetID()
s.listed_series={0x406}

function s.initial_effect(c)

	--① Revive next Standby Phase
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.regcon)
	e1:SetOperation(s.regop)
	c:RegisterEffect(e1)

	--② Special Summon if used as Synchro Material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

end

--Destroyed or Tributed
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) or c:IsReason(REASON_RELEASE)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local turn=Duel.GetTurnCount()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	e1:SetLabel(turn)
	e1:SetLabelObject(c)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	e1:SetReset(RESET_PHASE+PHASE_STANDBY,2)
	Duel.RegisterEffect(e1,tp)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()>e:GetLabel()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if not c then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if c:IsLocation(LOCATION_GRAVE)
	and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end

--② Synchro material condition
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return r==REASON_SYNCHRO and rc and rc:IsSetCard(0x406)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
end