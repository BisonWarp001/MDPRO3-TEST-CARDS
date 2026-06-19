-- High Priest of Jashin
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,21208154,62180201,57793869)
	-- (1) Revelar esta carta en mano, buscar, descartar e Invocar de Modo Especial
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- (2) Efecto al ser Tributado para un Dios Maligno (Robar o Destruir)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.wickedcon)
	e2:SetTarget(s.wickedtg)
	e2:SetOperation(s.wickedop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e2b)
	
	-- (3) Invocación por Sacrificio en el turno del oponente (Efecto Rápido)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,4))
	e3:SetCategory(CATEGORY_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMING_MAIN_END)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(s.sumcon)
	e3:SetTarget(s.sumtg)
	e3:SetOperation(s.sumop)
	c:RegisterEffect(e3)
end

-- Filtros para el Efecto (1)
function s.thfilter(c)
	return c:IsSetCard(0x3f2) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	
	-- Costo nativo: Mostrar este Sacerdote al oponente
	Duel.ConfirmCards(1-tp,c)
	
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		Duel.ShuffleHand(tp)
		if Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)>0 then
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
				Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-- Condición y Filtros para el Efecto (2)
function s.wickedcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return c:IsReason(REASON_SUMMON) and rc 
		and (rc:IsCode(21208154) or rc:IsCode(62180201) or rc:IsCode(57793869))
end
function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_FIEND)
end
function s.wickedtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	local mg=rc:GetMaterial()
	local ct=mg:FilterCount(s.matfilter,nil)
	if chk==0 then
		if ct==0 then return false end
		local b1=Duel.IsPlayerCanDraw(tp,ct) and Duel.GetFlagEffect(tp,id)==0
		local b2=Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) and Duel.GetFlagEffect(tp,id+100)==0
		return b1 or b2
	end
	
	local b1=Duel.IsPlayerCanDraw(tp,ct) and Duel.GetFlagEffect(tp,id)==0
	local b2=Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) and Duel.GetFlagEffect(tp,id+100)==0
	
	-- Menú de opciones: Robar cartas o Destruir cartas del rival
	local op=aux.SelectFromOptions(tp,
		{b1,aux.Stringid(id,2),1}, -- "Draw cards"
		{b2,aux.Stringid(id,3),2}) -- "Destroy cards"
		
	e:SetLabel(op,ct)
	if op==1 then
		e:SetCategory(CATEGORY_DRAW)
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		Duel.SetTargetPlayer(tp)
		Duel.SetTargetParam(ct)
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
	elseif op==2 then
		e:SetCategory(CATEGORY_DESTROY)
		Duel.RegisterFlagEffect(tp,id+100,RESET_PHASE+PHASE_END,0,1)
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	end
end
function s.wickedop(e,tp,eg,ep,ev,re,r,rp)
	local op,ct=e:GetLabel()
	if op==1 then
		local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
		Duel.Draw(p,d,REASON_EFFECT)
	elseif op==2 then
		-- Filtrar y seleccionar de 1 hasta 'ct' cartas del oponente para destruir
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,ct,nil)
		if #g>0 then
			Duel.HintSelection(g)
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end

-- Filtros para el Efecto (3)
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(1-tp) and Duel.IsMainPhase()
end
function s.advfilter(c)
	return c:IsSummonable(true,nil)
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.advfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.advfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end
