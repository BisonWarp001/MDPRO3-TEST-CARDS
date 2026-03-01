-- Defender of Divinity
local s,id=GetID()
s.listed_series={0x54b}
function s.initial_effect(c)
	aux.AddCodeList(c,15771991,10000000,10000010,10000020)
	-- Activación Trap Continua
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-------------------------------------------------
	-- Quick Effect: Negar activación usando un Slime en GY
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- HOPT/OATH
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- Condición: controlar Slifer, Obelisk o Ra
-------------------------------------------------
function s.godfilter(c)
	return c:IsFaceup() and (c:IsCode(10000020) -- Slifer
		or c:IsCode(10000000) -- Obelisk
		or c:IsCode(10000010)) -- Ra
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end
	return Duel.IsExistingMatchingCard(s.godfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsChainDisablable(ev)
end

-------------------------------------------------
-- Costo: remover 1 Slime o Guardian Slime en GY
-------------------------------------------------
function s.slimefilter(c)
	return c:IsAbleToRemoveAsCost() and 
		(c:IsSetCard(0x54b) or c:IsCode(15771991))
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.slimefilter,tp,LOCATION_GRAVE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.slimefilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	Duel.Remove(tc,POS_FACEUP,REASON_COST)

	-- Registrar End Phase AQUÍ
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetLabelObject(tc)
	e1:SetOperation(s.retop)
	Duel.RegisterEffect(e1,tp)
end

-------------------------------------------------
-- Target: negar efecto
-------------------------------------------------
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

-------------------------------------------------
-- Operation: negar y destruir, registrar End Phase
-------------------------------------------------
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end

-------------------------------------------------
-- End Phase: devolver Slime a la mano
-------------------------------------------------
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetLabelObject()
	if rc and rc:IsLocation(LOCATION_REMOVED) then
		Duel.SendtoHand(rc,nil,REASON_EFFECT)
	end
	if rc then rc:DeleteGroup() end
end