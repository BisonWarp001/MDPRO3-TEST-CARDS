-- Forbidden Seal of Orichalcos 
-- ID: 48179391
local s,id=GetID()
function s.initial_effect(c)
    -- Activar
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- Solo puedes activar 1 por turno
    c:RegisterEffect(e1)

    -- Nombre siempre tratado como "The Seal of Orichalcos" (Incondicional)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetCode(EFFECT_ADD_CODE)
    e2:SetValue(48179391)
    c:RegisterEffect(e2)

    -- (1) Todos los monstruos que controlas ganan 500 ATK
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_FZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetValue(500)
    c:RegisterEffect(e3)

    -- (2) Esta carta no puede ser seleccionada por efectos de cartas
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE) -- Cambiado a single_range para que se proteja a sí misma
    e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e4:SetRange(LOCATION_FZONE)
    e4:SetValue(aux.tgoval)
    c:RegisterEffect(e4)

    -- (3) Los monstruos que controlas y en tu GY se convierten en "Orichalcos"
    local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_ADD_SETCODE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(LOCATION_MZONE+LOCATION_GRAVE,0)
	e5:SetTarget(s.settg)
	e5:SetValue(0x3fc)
	c:RegisterEffect(e5)
end
function s.settg(e,c)
	return c:IsType(TYPE_MONSTER)
end