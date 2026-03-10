--Shadow Torment - Viser Des the Eternal Torture
local s,id=GetID()
s.listed_series={0x406}

function s.initial_effect(c)

	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	--On Summon: target monster cannot attack or activate effects
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)

	local e1x=e1:Clone()
	e1x:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1x)

	--Use opponent monster as Synchro material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.syntg)
	e2:SetOperation(s.synop)
	c:RegisterEffect(e2)

end

--target opponent monster
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then

		--cannot attack
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
		tc:RegisterEffect(e1)

		--cannot activate effects
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CANNOT_TRIGGER)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
		tc:RegisterEffect(e2)
	end
end

--filter opponent monster
function s.synfilter(c)
	return c:IsFaceup()
end

function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.synfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.synfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.synfilter,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local c=e:GetHandler()

	--allow use as synchro material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SYNCHRO_MATERIAL)
	e1:SetValue(s.synlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
end

function s.synlimit(e,c)
	return c:IsSetCard(0x406)
end