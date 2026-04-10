-- Obelisk the Tormentor Cult terminado
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,10000000)

	-- 1. IDENTIFICADOR (Permite que el sistema lo reconozca como sustituto de tributos)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(id)
	c:RegisterEffect(e0)

	-- 2. LÓGICA DE TRIBUTO TRIPLE (Solo para Obelisk)
	-- Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetCondition(s.ttcon)
	e1:SetTarget(s.RequireSummon)
	e1:SetOperation(s.ttop)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e1)
	-- Set (Por si acaso se intenta colocar, aunque los dioses usualmente no se colocan)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_LIMIT_SET_PROC)
	c:RegisterEffect(e1b)

	-- 3. INVOCACIÓN NORMAL NO PUEDE SER NEGADA
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e2)

	-- 4. BLOQUEO DE RESPUESTA
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetOperation(s.sumsuc)
	c:RegisterEffect(e3)

	-- 5. AUTO-DESTRUCCIÓN EN END PHASE (Si fue Special Summoned)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetCondition(s.tgcon)
	e4:SetTarget(s.tgtg)
	e4:SetOperation(s.tgop)
	c:RegisterEffect(e4)

	-- 6. QUICK EFFECT: BANISHEAR MAGIA/TRAMPA
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCountLimit(1)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)

	-- 7. QUICK EFFECT: DESDE GY PARA INVOCAR OBELISK
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_GRAVE)
	e6:SetCountLimit(1,id)
	e6:SetCost(aux.bfgcost)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

--------------------------------------------------
-- LÓGICA DE TRIBUTO (RESTRITO A OBELISK 10000000)
--------------------------------------------------

function s.ttfilter(c,tp)
	return c:IsHasEffect(id) and c:IsReleasable(REASON_SUMMON) and Duel.GetMZoneCount(tp,c)>0
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	-- minc<=3 asegura que puede sustituir hasta 3 tributos
	return minc<=3 and s.RequireSummon(e,c)
		and Duel.IsExistingMatchingCard(s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

function s.RequireSummon(e,c)
	-- EXCLUSIVAMENTE Obelisk the Tormentor
	return c:IsCode(10000000)
end

--------------------------------------------------
-- FUNCIONES AUXILIARES
--------------------------------------------------

function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,10000000) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,10000000)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end
