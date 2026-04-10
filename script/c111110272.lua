-- Authority of the Creator God
local s,id=GetID()

function s.initial_effect(c)
	aux.AddCodeList(c,10000000,10000010,10000020)
	
	-- Activar carta
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ① EFECTO RÁPIDO: OBELISK (Soul Energy Style)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,id) -- HOPT para el daño masivo
	e2:SetCondition(s.obcon)
	e2:SetCost(s.obcost)
	e2:SetTarget(s.obtg)
	e2:SetOperation(s.obop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- ② EFECTO RÁPIDO: RA (Pagar 1000 -> Destruir + Daño)
	-------------------------------------------------
	local e3=e2:Clone()
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.racon)
	e3:SetCost(s.racost)
	e3:SetTarget(s.ratg)
	e3:SetOperation(s.raop)
	c:RegisterEffect(e3)
    
    -- ③ SLIFER: Plus de Robo (Pasivo)
    local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_SZONE)
	e4:SetOperation(s.sliop)
	c:RegisterEffect(e4)
end

-------------------------------------------------
-- Lógica OBELISK (Copia Soul Energy MAX!!)
-------------------------------------------------
function s.obcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,10000000),tp,LOCATION_MZONE,0,1,nil)
end
function s.obcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroup(tp,nil,2,nil) end
	local g=Duel.SelectReleaseGroup(tp,nil,2,2,nil)
	Duel.Release(g,REASON_COST)
end
function s.obtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,4000)
end
function s.obop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		Duel.Damage(1-tp,4000,REASON_EFFECT)
	end
end

-------------------------------------------------
-- Lógica RA (Pagar 1000 -> Destruir + Daño ATK)
-------------------------------------------------
function s.racon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,10000010),tp,LOCATION_MZONE,0,1,nil)
end
function s.racost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.ratg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.raop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local atk=math.max(tc:GetTextAttack(),0)
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			Duel.Damage(1-tp,atk,REASON_EFFECT)
		end
	end
end

-------------------------------------------------
-- Lógica SLIFER (Robo automático)
-------------------------------------------------
function s.sliop(e,tp,eg,ep,ev,re,r,rp)
    if re and re:GetHandler():IsCode(10000020) and Duel.GetFlagEffect(tp,id+2)==0 then
        Duel.Hint(HINT_CARD,0,id)
        Duel.Draw(tp,1,REASON_EFFECT)
        Duel.RegisterFlagEffect(tp,id+2,RESET_PHASE+PHASE_END,0,1)
    end
end
