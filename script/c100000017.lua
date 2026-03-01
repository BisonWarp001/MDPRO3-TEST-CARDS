-- Egyptian God Slime - Eternal FINALIZADO no cambiar
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion material
	c:EnableReviveLimit()
	aux.AddFusionProcFun2(c,
		aux.FilterBoolFunction(Card.IsRace,RACE_AQUA),
		function(c)
			return c:IsAttribute(ATTRIBUTE_WATER) and c:IsLevel(10)
		end,
		true
	)

	-- Name becomes Egyptian God Slime
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(42166000)
	c:RegisterEffect(e0)

	-- Special Summon limit
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)

	-- Special Summon from Extra Deck (tribute)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.hspcon)
	e2:SetTarget(s.hsptg)
	e2:SetOperation(s.hspop)
	c:RegisterEffect(e2)

	-- God Slime marker
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(42166000)
	c:RegisterEffect(e3)

	-- Counts as 1/2/3 Tributes
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_DOUBLE_TRIBUTE)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_TRIPLE_TRIBUTE)
	e5:SetValue(1)
	c:RegisterEffect(e5)
		-- Triple Tribute system (God support)
	local eGod=Effect.CreateEffect(c)
	eGod:SetType(EFFECT_TYPE_SINGLE)
	eGod:SetCode(42166000)
	c:RegisterEffect(eGod)

	-- Require 3 tributes (Summon)
	local eTT=Effect.CreateEffect(c)
	eTT:SetDescription(aux.Stringid(42166000,0))
	eTT:SetType(EFFECT_TYPE_FIELD)
	eTT:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	eTT:SetRange(LOCATION_MZONE)
	eTT:SetTargetRange(LOCATION_HAND,0)
	eTT:SetCondition(s.ttcon)
	eTT:SetTarget(s.RequireSummon)
	eTT:SetOperation(s.ttop)
	eTT:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(eTT)

	-- Require 3 tributes (Set)
	local eTT2=eTT:Clone()
	eTT2:SetCode(EFFECT_LIMIT_SET_PROC)
	eTT2:SetTarget(s.RequireSet)
	c:RegisterEffect(eTT2)

	-- Can tribute 3 monsters (self tribute support)
	local eTT3=eTT:Clone()
	eTT3:SetCode(EFFECT_SUMMON_PROC)
	eTT3:SetTarget(s.CanSummon)
	eTT3:SetValue(SUMMON_TYPE_ADVANCE+SUMMON_VALUE_SELF)
	c:RegisterEffect(eTT3)

	-- 5 tribute case (Ra Sphere Mode)
	local eTT5=eTT:Clone()
	eTT5:SetCode(EFFECT_SUMMON_PROC)
	eTT5:SetTarget(aux.TargetBoolFunction(Card.IsCode,5008836))
	eTT5:SetCondition(s.t5con)
	eTT5:SetOperation(s.t5op)
	eTT5:SetValue(SUMMON_TYPE_ADVANCE+SUMMON_VALUE_SELF)
	c:RegisterEffect(eTT5)

	-- Cannot be destroyed by battle
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e6:SetValue(1)
	c:RegisterEffect(e6)

	-- Protection (battle + target)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e7:SetRange(LOCATION_MZONE)
	e7:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e7:SetTargetRange(LOCATION_MZONE,0)
	e7:SetTarget(s.prottg)
	e7:SetValue(aux.tgoval)
	c:RegisterEffect(e7)

	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_FIELD)
	e8:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e8:SetRange(LOCATION_MZONE)
	e8:SetTargetRange(0,LOCATION_MZONE)
	e8:SetValue(s.prottg)
	c:RegisterEffect(e8)

	-- Equip (Relinquished)
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,0))
	e9:SetType(EFFECT_TYPE_IGNITION)
	e9:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1)
	e9:SetCondition(s.eqcon)
	e9:SetTarget(s.eqtg)
	e9:SetOperation(s.eqop)
	c:RegisterEffect(e9)

	-- ATK / DEF
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_SINGLE)
	e10:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCode(EFFECT_SET_ATTACK)
	e10:SetCondition(s.adcon)
	e10:SetValue(s.atkval)
	c:RegisterEffect(e10)

	local e11=e10:Clone()
	e11:SetCode(EFFECT_SET_DEFENSE)
	e11:SetValue(s.defval)
	c:RegisterEffect(e11)

	-- Destroy equip & burn
	local e12=Effect.CreateEffect(c)
	e12:SetDescription(aux.Stringid(id,1))
	e12:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e12:SetType(EFFECT_TYPE_IGNITION)
	e12:SetRange(LOCATION_MZONE)
	e12:SetCountLimit(1)
	e12:SetTarget(s.destg)
	e12:SetOperation(s.desop)
	c:RegisterEffect(e12)

	-- Destruction replacement
	local e13=Effect.CreateEffect(c)
	e13:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e13:SetCode(EFFECT_DESTROY_REPLACE)
	e13:SetTarget(s.reptg)
	e13:SetOperation(s.repop)
	c:RegisterEffect(e13)
end

function s.splimit(e,se,sp,st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA) or aux.fuslimit(e,se,sp,st)
end

-- Extra Deck tribute summon
function s.hspfilter(c,tp,sc)
	return c:IsRace(RACE_AQUA)
		and c:IsAttribute(ATTRIBUTE_WATER)
		and c:IsLevel(10)
		and c:IsControler(tp)
		and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0
		and c:IsCanBeFusionMaterial(sc,SUMMON_TYPE_SPECIAL)
end

function s.hspcon(e,c)
	if c==nil then return true end
	return Duel.CheckReleaseGroupEx(c:GetControler(),s.hspfilter,1,REASON_SPSUMMON,false,nil,c:GetControler(),c)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetReleaseGroup(tp,false,REASON_SPSUMMON):Filter(s.hspfilter,nil,tp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=g:SelectUnselect(nil,tp,false,true,1,1)
	if tc then
		e:SetLabelObject(tc)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local tc=e:GetLabelObject()
	c:SetMaterial(Group.FromCards(tc))
	Duel.Release(tc,REASON_SPSUMMON)
end
function s.ttfilter(c,tp)
	return c:IsHasEffect(42166000)
		and c:IsReleasable(REASON_SUMMON)
		and Duel.GetMZoneCount(tp,c)>0
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc<=3
		and Duel.IsExistingMatchingCard(s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

-- Egyptian Gods + Wicked + Metaltron
function s.RequireSummon(e,c)
	return c:IsCode(10000000,10000010,10000020,10000080,
		21208154,57793869,62180201,57761191)
end

function s.RequireSet(e,c)
	return c:IsCode(21208154,57793869,62180201)
end

-- Cards that can tribute normally but benefit
function s.CanSummon(e,c)
	return c:IsCode(3912064,25524823,36354007,75285069,78651105)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

-- 5 tribute case
function s.gchk(g,tc,tp)
	return g:IsExists(s.ttfilter,1,nil,tp)
		and Duel.CheckTribute(tc,#g,#g,g)
end

function s.t5con(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	return minc<=5 and g:CheckSubGroup(s.gchk,3,3,c,tp)
end

function s.t5op(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,2,2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local sg=Duel.SelectMatchingCard(tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,g,tp)
	g:Merge(sg)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

-- Protection helper
function s.prottg(e,c)
	return not (c:IsCode(42166000) and c:IsFaceup())
end

-- Equip logic
function s.eqfilter(c)
	return c:GetFlagEffect(id)~=0
end
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetEquipGroup():GetCount()==0
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if not Duel.Equip(tp,tc,c,false) then return end
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetValue(function(e,c) return e:GetOwner()==c end)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetValue(1)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)
end

-- ATK/DEF
function s.adcon(e)
	return e:GetHandler():GetEquipGroup():IsExists(s.eqfilter,1,nil)
end
function s.atkval(e)
	local tc=e:GetHandler():GetEquipGroup():Filter(s.eqfilter,nil):GetFirst()
	return tc and math.max(tc:GetTextAttack(),0) or 0
end
function s.defval(e)
	local tc=e:GetHandler():GetEquipGroup():Filter(s.eqfilter,nil):GetFirst()
	return tc and math.max(tc:GetTextDefense(),0) or 0
end

-- Destroy & burn
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetEquipGroup():GetCount()>0 end
	local tc=e:GetHandler():GetEquipGroup():GetFirst()
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,tc:GetBaseAttack()/2)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetHandler():GetEquipGroup():GetFirst()
	if tc and Duel.Destroy(tc,REASON_EFFECT)~=0 then
		Duel.Damage(1-tp,tc:GetBaseAttack()/2,REASON_EFFECT)
	end
end

-- Destruction replace
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	return chk==0 and e:GetHandler():GetEquipGroup():GetCount()>0
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetHandler():GetEquipGroup():GetFirst()
	if tc then Duel.Destroy(tc,REASON_EFFECT) end
end