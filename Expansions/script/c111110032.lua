--Tyr, Champion of the Aesir
local s,id=GetID()

s.listed_series={0x42,0x5042,0x4b}

function s.initial_effect(c)
	-- Synchro Summon (PATTERN FREYA)
	aux.AddSynchroProcedure(c,s.tfilter,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	------------------------------------------------
	--① If Synchro Summoned: Bounce (HOPT)
	------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id) -- HOPT
	e1:SetCondition(s.bounce_con)
	e1:SetTarget(s.bounce_tg)
	e1:SetOperation(s.bounce_op)
	c:RegisterEffect(e1)

	------------------------------------------------
	--② If opponent SS except from hand: Draw (HOPT)
	------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) -- HOPT
	e2:SetCondition(s.draw_con)
	e2:SetTarget(s.draw_tg)
	e2:SetOperation(s.draw_op)
	c:RegisterEffect(e2)

	------------------------------------------------
	--③ Register sent to GY this turn
	------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)

	------------------------------------------------
	--④ End Phase: Set Nordic Relic (HOPT)
	------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id) -- HOPT
	e4:SetCondition(s.set_con)
	e4:SetTarget(s.set_tg)
	e4:SetOperation(s.set_op)
	c:RegisterEffect(e4)
end

-------------------------------------------------
-- Synchro material filter
-------------------------------------------------
function s.tfilter(c)
	if not c:IsType(TYPE_TUNER) then return false end
	return c:IsSetCard(0x3042)
		or c:IsSetCard(0x6042)
		or c:IsSetCard(0xA042)
		or c:IsHasEffect(61777313)
end
------------------------------------------------
--① Bounce
------------------------------------------------
function s.bounce_con(e,tp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.bounce_filter_op(c)
	return c:IsFaceup() and c:IsAbleToHand()
end
function s.bounce_filter_gy(c)
	return c:IsSetCard(0x42) and c:IsAbleToHand()
end

function s.bounce_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.bounce_filter_op,tp,0,LOCATION_MZONE,1,nil)
			or Duel.IsExistingMatchingCard(s.bounce_filter_gy,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,0)
end

function s.bounce_op(e,tp)
	local has_op=Duel.IsExistingMatchingCard(s.bounce_filter_op,tp,0,LOCATION_MZONE,1,nil)
	local has_gy=Duel.IsExistingMatchingCard(s.bounce_filter_gy,tp,LOCATION_GRAVE,0,1,nil)
	if not has_op and not has_gy then return end

	local sel
	if has_op and has_gy then
		sel=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif has_op then
		sel=0
	else
		sel=1
	end

	if sel==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local g=Duel.SelectMatchingCard(tp,s.bounce_filter_op,tp,0,LOCATION_MZONE,1,1,nil)
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.bounce_filter_gy,tp,LOCATION_GRAVE,0,1,1,nil)
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

------------------------------------------------
--② Draw
------------------------------------------------
function s.draw_filter(c,tp)
	return c:IsSummonPlayer(1-tp)
		and c:GetSummonLocation()~=LOCATION_HAND
end

function s.draw_con(e,tp,eg)
	return eg:IsExists(s.draw_filter,1,nil,tp)
end

function s.draw_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.draw_op(e,tp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

------------------------------------------------
--③ Register sent to GY this turn
------------------------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsPreviousLocation(LOCATION_MZONE) then
		c:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
	end
end

------------------------------------------------
--④ End Phase: Set Nordic Relic
------------------------------------------------
function s.set_con(e,tp)
	return e:GetHandler():GetFlagEffect(id)~=0
end

function s.set_filter(c)
	return c:IsSetCard(0x5042)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
end

function s.set_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.set_filter,tp,LOCATION_DECK,0,1,nil)
	end
end

function s.set_op(e,tp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local tc=Duel.SelectMatchingCard(tp,s.set_filter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if not tc then return end
	Duel.SSet(tp,tc)

	-- Cannot activate unless you control an Aesir
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetCondition(function(e)
		return not Duel.IsExistingMatchingCard(
			Card.IsSetCard,e:GetHandlerPlayer(),
			LOCATION_MZONE,0,1,nil,0x4b
		)
	end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end