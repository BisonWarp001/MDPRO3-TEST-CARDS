--Dark Spirit of the Possessed

local s,id=GetID()
function s.initial_effect(c)

	--Link Summon
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsLinkType,TYPE_EFFECT),2,2,s.lcheck)
	c:EnableReviveLimit()

	--Destroy 1 Spell/Trap
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon1)
	e1:SetCost(s.descost1)
	e1:SetTarget(s.destg1)
	e1:SetOperation(s.desop1)
	c:RegisterEffect(e1)

	--Switch ATK and DEF
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SWAP_BASE_AD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.adcon)
	c:RegisterEffect(e2)

	--Battle effects (Co-Linked: Banish, Not Co-Linked: Destroy + Damage)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)

	--Battle effects (Not Co-Linked: Destroy + Damage)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BATTLED)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	--Special Summon on destruction
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(1,id+100)
	e5:SetCondition(s.spcon)
	e5:SetCost(s.spcost)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)
end

--Link Material Requirement
function s.lcheck(g)
	return g:IsExists(Card.IsLinkSetCard,1,nil,0xfa1)
end

--Effect ①: Discard 1 card to destroy a Spell/Trap
function s.descon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.descost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.destg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

--Effect ②: Swap ATK and DEF of opponent's monsters while this card points to a monster
function s.adcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetLinkedGroup():IsExists(s.adfilter,1,nil)
end

function s.adfilter(c)
	return c:IsType(TYPE_MONSTER)
end

--Effect ③: Battle effect (Co-Linked: Banish, Not Co-Linked: Destroy + Inflict damage)
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc then return false end
	e:SetLabelObject(bc)
	return c:GetMutualLinkedGroupCount()>0 and c:IsStatus(STATUS_OPPO_BATTLE) and bc:IsControler(1-tp) and bc:IsRelateToBattle()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetLabelObject()
	if not bc then return false end
	if chk==0 then return bc:IsAbleToRemove() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetLabelObject()
	if not bc then return end
	if bc:IsRelateToBattle() and bc:IsControler(1-tp) then
		Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)
	end
end

--Effect ④: Battle effect (Not Co-Linked: Destroy + Inflict damage)
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc then return false end
	e:SetLabelObject(bc)
	return c:GetMutualLinkedGroupCount()==0 and c:IsStatus(STATUS_OPPO_BATTLE) and bc:IsControler(1-tp) and bc:IsRelateToBattle()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetLabelObject()
	if not bc then return false end
	if chk==0 then return true end
	local dam=bc:GetTextAttack()
	if dam<0 then dam=0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,dam)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetLabelObject()
	if not bc then return end
	if bc:IsRelateToBattle() and bc:IsControler(1-tp) and Duel.Destroy(bc,REASON_EFFECT)~=0 then
		local dam=bc:GetTextAttack()
		if dam<0 then dam=0 end
		Duel.Damage(1-tp,dam,REASON_EFFECT)
	end
end

--Effect ⑤: If destroyed by battle or card effect, pay 1500 LP to Special Summon, destroy the attacking monster, and inflict 1000 damage
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_BATTLE+REASON_EFFECT)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1500) end
	Duel.PayLPCost(tp,1500)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	local tc=Duel.GetAttacker()  -- Target the attacking monster
	if chk==0 then return tc and tc:IsOnField() and tc:IsCanBeEffectTarget(e) end
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		if tc and tc:IsRelateToBattle() and Duel.Destroy(tc,REASON_EFFECT)~=0 then
			Duel.Damage(1-tp,1000,REASON_EFFECT)
		end
	end
end
