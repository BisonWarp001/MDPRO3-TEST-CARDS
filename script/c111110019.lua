--Divine God Slime
local s,id=GetID()
function s.initial_effect(c)
	--fusion material
	c:EnableReviveLimit()
	aux.AddFusionProcFun2(c,aux.FilterBoolFunction(Card.IsRace,RACE_AQUA),s.ffilter,true)

	--spsummon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)

	--spsummon proc (Tributing 1 Level 10 Aqua 0 ATK)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.hspcon)
	e2:SetTarget(s.hsptg)
	e2:SetOperation(s.hspop)
	c:RegisterEffect(e2)

	--triple tribute logic (REPLICA EXACTA KONAMI)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(id) -- ID para ttfilter
	c:RegisterEffect(e0)

	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_HAND,0)
	e3:SetCondition(s.ttcon)
	e3:SetTarget(s.RequireSummon)
	e3:SetOperation(s.ttop)
	e3:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EFFECT_LIMIT_SET_PROC)
	e4:SetTarget(s.RequireSet)
	c:RegisterEffect(e4)

	local e5=e3:Clone()
	e5:SetCode(EFFECT_SUMMON_PROC)
	e5:SetTarget(s.CanSummon)
	e5:SetValue(SUMMON_TYPE_ADVANCE+SUMMON_VALUE_SELF)
	c:RegisterEffect(e5)

	--Protection: Opponent cannot destroy monsters you control with effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(LOCATION_MZONE,0)
	e6:SetTarget(s.tgtg)
	e6:SetValue(s.indval)
	c:RegisterEffect(e6)

	--Inherit: DIVINE monster unaffected by activated effects
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_BE_PRE_MATERIAL)
	e7:SetCondition(s.regcon)
	e7:SetOperation(s.regop)
	c:RegisterEffect(e7)

	--GY Effect: Shuffle and gain 4000 LP
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_RECOVER+CATEGORY_TODECK)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetRange(LOCATION_GRAVE)
	e8:SetCountLimit(1,id)
	e8:SetCondition(s.lpcon)
	e8:SetTarget(s.lptg)
	e8:SetOperation(s.lpop)
	c:RegisterEffect(e8)

	--LP Payment Detector
	if not s.global_check then
		s.global_check=true
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_PAY_LPCOST)
		ge:SetOperation(s.lpreg)
		Duel.RegisterEffect(ge,0)
	end
end

--------------------------------------------------
-- FUSION & PROCEDURES
--------------------------------------------------

function s.ffilter(c)
	return c:IsFusionAttribute(ATTRIBUTE_WATER) and c:IsLevel(10)
end

function s.splimit(e,se,sp,st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA) or aux.fuslimit(e,se,sp,st)
end

function s.hspfilter(c,tp,sc)
	return c:IsAttack(0) and c:IsRace(RACE_AQUA) and c:IsLevel(10)
		and c:IsControler(tp) and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0 and c:IsCanBeFusionMaterial(sc,SUMMON_TYPE_SPECIAL)
end

function s.hspcon(e,c)
	if c==nil then return true end
	return Duel.CheckReleaseGroupEx(c:GetControler(),s.hspfilter,1,REASON_SPSUMMON,false,nil,c:GetControler(),c)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetReleaseGroup(tp,false,REASON_SPSUMMON):Filter(s.hspfilter,nil,tp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=g:SelectUnselect(nil,tp,false,true,1,1)
	if tc then
		e:SetLabelObject(tc)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local tc=e:GetLabelObject()
	c:SetMaterial(Group.FromCards(tc))
	Duel.Release(tc,REASON_SPSUMMON)
end

--------------------------------------------------
-- TRIBUTE REPLICA (LÓGICA ORIGINAL KONAMI)
--------------------------------------------------

function s.ttfilter(c,tp)
	return c:IsHasEffect(id) and c:IsReleasable(REASON_SUMMON) and Duel.GetMZoneCount(tp,c)>0
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc<=3 and Duel.IsExistingMatchingCard(s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

function s.RequireSummon(e,c)
	return c:IsCode(10000000,10000010,10000020,10000080,21208154,57793869,62180201,57761191,111110200,111110201,111110202,111110051,111110055,111110058)
end

function s.RequireSet(e,c)
	return c:IsCode(21208154,57793869,62180201)
end

function s.CanSummon(e,c)
	return c:IsCode(3912064,25524823,36354007,75285069,78651105)
end

--------------------------------------------------
-- PROTECTION & INHERIT
--------------------------------------------------

function s.tgtg(e,c)
	return not (c:IsCode(id) and c:IsFaceup())
end

function s.indval(e,re,tp)
	return tp~=e:GetHandlerPlayer()
end

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return r==REASON_SUMMON and rc and rc:IsAttribute(ATTRIBUTE_DIVINE)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if not rc then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1)
end

function s.efilter(e,re)
	return re:IsActivated() and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--------------------------------------------------
-- GY RECOVERY
--------------------------------------------------

function s.lpreg(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(ep,id,RESET_PHASE+PHASE_END,0,1)
end

function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end

function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtra() end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,4000)
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.Recover(tp,4000,REASON_EFFECT)
	end
end
