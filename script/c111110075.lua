-- Legacy of the Dark Gods
local s,id=GetID()

function s.initial_effect(c)
	-- Activar carta
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- Mencionar las cartas para el motor de búsqueda
	aux.AddCodeList(c,21208154,62180201,57793869)

	-- Efecto Principal (Main Phase)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	-- Se eliminó s.cost para cumplir con tu nuevo wording
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,0,0,0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Normal Summon adicional
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- 2. La Invocación Normal no puede ser negada
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e2:SetProperty(EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_SET_AVAILABLE)
	e2:SetTargetRange(1,0)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)

	-- 3. Esta carta no puede ser destruida por efectos
	if c:IsRelateToEffect(e) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e3:SetRange(LOCATION_SZONE)
		e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e3:SetValue(1)
		e3:SetReset(RESET_PHASE+PHASE_END)
		c:RegisterEffect(e3)
	end

	-- 4. Protección para los Wicked Gods
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.godfilter)
	e4:SetValue(aux.tgoval)
	e4:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e4,tp)
end

function s.godfilter(e,c)
	return c:IsCode(21208154, 62180201, 57793869)
end
