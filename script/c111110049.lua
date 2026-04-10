-- Judgment of the Ancient Gods Terminado
local s,id=GetID()

function s.initial_effect(c)
	-- Mencionar a Ra
	aux.AddCodeList(c,10000010)
	
	-- (1) Negate + Banish + Damage (Ra)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- (2) GY -> Set Quick-Play/Trap (Not Ra)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.setcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

--====================================
-- LÓGICA (1): NEGACIÓN
--====================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DIVINE)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		if Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)~=0 then
			-- Chequeo directo por ID en el campo de monstruos del jugador (tp)
			if Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,10000010) then
				Duel.BreakEffect()
				Duel.Damage(1-tp,2000,REASON_EFFECT)
			end
		end
	end
end

--====================================
-- LÓGICA (2): SET DESDE GY
--====================================
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	-- Divine-Beast que NO sea Ra
	return Duel.IsExistingMatchingCard(function(c) 
		return c:IsFaceup() and c:IsRace(RACE_DIVINE) and not c:IsCode(10000010) 
	end,tp,LOCATION_MZONE,0,1,nil)
end

function s.setfilter(c)
	return (c:IsType(TYPE_QUICKPLAY) or c:IsType(TYPE_TRAP)) and c:IsSSetable() and not c:IsCode(id)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.SSet(tp,tc)>0 then
		-- Permitir activación este turno
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		if tc:IsType(TYPE_QUICKPLAY) then
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		else
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		end
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end
