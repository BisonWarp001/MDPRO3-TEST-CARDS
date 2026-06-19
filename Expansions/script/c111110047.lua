-- Avatar of the Chosen Faraoh terminado
local s,id=GetID()
s.listed_series={0x4b0}
function s.initial_effect(c)
	-- Identificador para el motor de tributos (Igual que God Slime)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(id) 
	c:RegisterEffect(e1)
	
	-- Lógica de Triple Tributo Dinámico (1 o 3 tributos)
	-- Este bloque permite que la carta valga por 3, pero no bloquea el uso de otros materiales
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetCondition(s.ttcon)
	e2:SetTarget(s.tttg)
	e2:SetOperation(s.ttop)
	e2:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_SUMMON_PROC)
	e3:SetValue(SUMMON_TYPE_ADVANCE+SUMMON_VALUE_SELF)
	c:RegisterEffect(e3)

	-- (1) Efecto al ser tributado: Equipar y negar
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_EQUIP+CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_RELEASE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)
end

-- Lógica de Tributo (Basada en God Slime)
function s.ttfilter(c,tp)
	return c:IsHasEffect(id) and c:IsReleasable(REASON_SUMMON) and Duel.GetMZoneCount(tp,c)>0
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	-- Permite la invocación si minc es 3 (como los Dioses) y controlas esta carta
	return minc<=3 and Duel.IsExistingMatchingCard(s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.tttg(e,c)
	-- Solo aplica para Divine-Beast
	return c:IsRace(RACE_DIVINE)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	-- Esta operación permite al motor de juego elegir si usar esta carta sola
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

-- Lógica de Equipar y Negar (Mantenida de tu script original)
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) then return end
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		if Duel.Equip(tp,c,tc) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetLabelObject(tc)
			e1:SetValue(s.eqlimit)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_EQUIP)
			e2:SetCode(EFFECT_DISABLE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e2)
			local e3=e2:Clone()
			e3:SetCode(EFFECT_DISABLE_EFFECT)
			c:RegisterEffect(e3)
		end
	end
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end
