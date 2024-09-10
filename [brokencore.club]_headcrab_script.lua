-- Файл: lua/entities/headcrab_script.lua

DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Headcrab"
ENT.Author = "Hramov"
ENT.Information = "A headcrab entity"
ENT.Category = "Custom Entities"
ENT.Model = "models/headcrab.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 16))
    
    self:SetNWBool("Grabbing", false)
    self:SetNWEntity("Target", nil)
    self.NextDamageTime = CurTime()
end

function ENT:GrabTarget()
    local target = self:GetNWEntity("Target")
    if IsValid(target) then
        target:SetMoveType(MOVETYPE_NONE)
        target:SetNoDraw(true)
        target:SetNotSolid(true)

        local targetPos = target:GetPos() + Vector(0, 0, 20)
        local currentPos = self:GetPos()
        local direction = (targetPos - currentPos):GetNormalized()
        local distance = currentPos:Distance(targetPos)
        local speed = math.min(5, distance / 2)
        
        local newPos = currentPos + direction * speed
        self:SetPos(newPos)
        
        local trace = util.TraceLine({
            start = currentPos,
            endpos = newPos,
            filter = self
        })
        if trace.Hit then
            self:SetPos(trace.HitPos)
        end
        
        target:SetPos(self:GetPos() - Vector(0, 0, 20))
        
        -- Отображение надписи на экране
        local name = target:Nick()
        local text = "Вы управляете игроком: " .. name
        hook.Add("HUDPaint", "HeadcrabHUD", function()
            if IsValid(target) and target == self:GetNWEntity("Target") then
                draw.SimpleText(text, "Trebuchet24", ScrW() / 2, ScrH() / 2 - 50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end)
        
        if CurTime() >= self.NextDamageTime then
            target:TakeDamage(5, self, self)
            self.NextDamageTime = CurTime() + 10
        end
    end
end

function ENT:ReleaseTarget()
    local target = self:GetNWEntity("Target")
    if IsValid(target) then
        target:SetMoveType(MOVETYPE_WALK)
        target:SetNoDraw(false)
        target:SetNotSolid(false)
    end
    self:SetNWBool("Grabbing", false)
    self:SetNWEntity("Target", nil)
end

function ENT:Think()
    if self:GetNWBool("Attacking") then
        self:Attack()
    end

    if self:GetNWBool("Grabbing") then
        self:GrabTarget()
    end

    self:NextThink(CurTime())
    return true
end

hook.Add("Think", "HeadcrabControl", function()
    for _, ent in pairs(ents.FindByClass("headcrab_script")) do
        local attacking = input.IsMouseDown(MOUSE_LEFT)
        local grabbing = input.IsMouseDown(MOUSE_RIGHT)
        
        ent:SetNWBool("Attacking", attacking)
        ent:SetNWBool("Grabbing", grabbing)
        
        if grabbing then
            local nearestPlayer = nil
            local shortestDistance = 1000
            for _, ply in pairs(player.GetAll()) do
                local distance = ent:GetPos():Distance(ply:GetPos())
                if distance < shortestDistance then
                    nearestPlayer = ply
                    shortestDistance = distance
                end
            end
            ent:SetNWEntity("Target", nearestPlayer or nil)
        elseif not grabbing and ent:GetNWBool("Grabbing") then
            ent:ReleaseTarget()
        end
    end
end)

scripted_ents.Register(ENT, "headcrab_script")
