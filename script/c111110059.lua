-- Temple of the Eternal Pharaoh terminado
local s,id=GetID()
function s.initial_effect(c)
	-- 1. ACTIVACIÓN
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- (1) Aumento de ATK/DEF para "Cult"
	-- Nota: Asegúrate que tus monstruos tengan el SetCard 0x4b0
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetValue(500)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- (2) Invocar 1 DARK Priest Token
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)

	-- (3) Protección contra selección (Target)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e5:SetRange(LOCATION_FZONE)
	e5:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e5:SetTargetRange(LOCATION_MZONE,0)
	e5:SetTarget(aux.TRUE) -- Protege a TODOS tus monstruos
	e5:SetValue(aux.tgoval)
	c:RegisterEffect(e5)
end

-- Filtro para monstruos "Cult" (Por SetCard o por nombre)
function s.atktg(e,c)
	return c:IsSetCard(0x4b0) or c:IsType(TYPE_MONSTER) and c:IsCode(id_de_algun_cult) -- Opcional: c:GetText():find("Cult")
end

-- Lógica (2): DARK Priest Token
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,111110061,0,TYPES_TOKEN,0,0,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,111110061,0,TYPES_TOKEN,0,0,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) then return end
	local token=Duel.CreateToken(tp,111110061)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end
