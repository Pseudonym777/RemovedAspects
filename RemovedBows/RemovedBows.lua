--[[
    RemovedBows v0.1
    Author:
        pseudo

    Replaces Zag Bow with the Beam Bow, and chiron with charge bow, aspects that are in traitdata + a few bug fixes to make them a bit more playable

    Beam bow has a rapid fire very low damage laser attack, and a high damage arial barrage special.

    Charge bow can charge up multiple arrows into one attack, then release with a few bonus projectiles.
    It can also dash while charging attack without releasing.
    It has a wide spread barrage special with low damage


]]
ModUtil.Mod.Register("RemovedBows")
ModUtil.LoadOnce(function()
WeaponUpgradeData.BowWeapon[1] =
    {
        Costs = { 0, 0, 0, 0, 0 },
        MaxUpgradeLevel = 1,
        TraitName = "BowBeamTrait",
        EquippedKitAnimation = "WeaponBowAlt03FloatingIdleOff",
        UnequippedKitAnimation = "WeaponBowAlt03FloatingIdle",
        BonusUnequippedKitAnimation = "WeaponBowAlt03FloatingIdleBonus",
        BonusEquippedKitAnimation = "WeaponBowAlt03FloatingIdleOffBonus",
        Image = "Codex_Portrait_BowAlt03",
    }
WeaponUpgradeData.BowWeapon[2] =
    {
        Costs = { 0, 0, 0, 0, 0 },
        MaxUpgradeLevel = 1,
        TraitName = "BowStoredChargeTrait",
        EquippedKitAnimation = "WeaponBowAlt03FloatingIdleOff",
        UnequippedKitAnimation = "WeaponBowAlt03FloatingIdle",
        BonusUnequippedKitAnimation = "WeaponBowAlt03FloatingIdleBonus",
        BonusEquippedKitAnimation = "WeaponBowAlt03FloatingIdleOffBonus",
        Image = "Codex_Portrait_BowAlt03",
    }
end)
--enable arrow storage mechanic
OnWeaponCharging{ "BowWeapon",
	function( triggerArgs )
		if HeroHasTrait("BowStoredChargeTrait") then
		DoBowChargeX()
		end

	end
}
OnWeaponCharging{ "BowWeaponDash",
	function( triggerArgs )
		if HeroHasTrait("BowStoredChargeTrait") then
		DoBowDashChargeX()
		end

	end
}
OnWeaponFired{ "BowWeapon",
	function( triggerArgs )
		if HeroHasTrait("BowStoredChargeTrait") then
			EmptyBowChargeX( math.floor( CurrentRun.CurrentRoom.ChargeTicksReached / 10 ))
		end
	end
}
OnWeaponFired{ "BowWeaponDash",
	function( triggerArgs )
		if HeroHasTrait("BowStoredChargeTrait") then
			EmptyBowDashChargeX( math.floor( CurrentRun.CurrentRoom.ChargeTicksReached / 10 ))
		end
	end
}
--load assets for attacks
ModUtil.Path.Wrap( "SetupMap", function(baseFunc)
        LoadPackages({Names = {
            "AresUpgrade",
            "DemeterUpgrade",
        }})
        return baseFunc()
    end)
function DoBowDashChargeX()
	if CurrentRun.CurrentRoom.BowCharging then
		return
	end

	local tickRate = 0.1
	local ticksPerStage = 10
	local maxStage = 2

	wait(0.1, RoomThreadName )
	CurrentRun.CurrentRoom.BowCharging = true
	CurrentRun.CurrentRoom.ChargeTicksReached = CurrentRun.CurrentRoom.ChargeTicksReached or 0
	SetWeaponProperty({ WeaponName = "RushWeapon", DestinationId = CurrentRun.Hero.ObjectId, Property = "FireGraphic", Value = "ZagreusBowDashFireEndLoop" })
	SetWeaponProperty({ WeaponName = "RushWeapon", DestinationId = CurrentRun.Hero.ObjectId, Property = "PostBlinkAnim", Value = "ZagreusBowDashFireEndLoop" })
	while GetWeaponProperty({ Id = CurrentRun.Hero.ObjectId, WeaponName = "BowWeaponDash", Property = "Charging" }) do
		local stage = math.floor( CurrentRun.CurrentRoom.ChargeTicksReached / ticksPerStage )
		if CurrentRun.CurrentRoom.ChargeTicksReached % ticksPerStage == 0 then
			PlaySound({ Name = "/Leftovers/SFX/AuraOnLoud" })
			Flash({ Id = CurrentRun.Hero.ObjectId, Speed = 4, MinFraction = 0.5, MaxFraction = 0.6, Color = Color.White, Duration = 0.3 })
			local updateString = tostring(stage + 1)
			if stage == maxStage then
				if  CheckCooldown("MaxCharge", 1.0) then
					WeaponData.SpearWeaponSpin.MaxChargeText.TargetId = CurrentRun.Hero.ObjectId
					thread( InCombatTextArgs, WeaponData.SpearWeaponSpin.MaxChargeText )
				end
			elseif stage > 0 then
				thread( InCombatTextArgs, { TargetId = CurrentRun.Hero.ObjectId, Text = updateString, Duration = 1.0 })
			end
			Rumble({ LeftFraction = 0.45, Duration = 0.3 })

			local stageScaleModifier = 0.6
			SetWeaponProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "NumProjectileWaves", Value = 1 + stage })
			SetProjectileProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "Scale", Value = 1 + stage * stageScaleModifier })
			SetProjectileProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "ExtentScale", Value = 1 + stage * 0.25 })

		end
		if stage ~= maxStage then
			CurrentRun.CurrentRoom.ChargeTicksReached = CurrentRun.CurrentRoom.ChargeTicksReached + 1
		end
		wait(tickRate, RoomThreadName)
	end
	CurrentRun.CurrentRoom.BowCharging = false
end
function EmptyBowDashChargeX( stageReached )
	if stageReached >= 1 then
		Rumble({ RightFraction = 0.7, Duration = 0.3 })
		FireWeaponFromUnit({ Weapon = "ChargeBowWeapon1", Id = CurrentRun.Hero.ObjectId, DestinationId = CurrentRun.Hero.ObjectId })
	end
	if stageReached >= 2 then
		FireWeaponFromUnit({ Weapon = "MaxChargeBowWeapon", Id = CurrentRun.Hero.ObjectId, DestinationId = CurrentRun.Hero.ObjectId })
	end
	SetWeaponProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "NumProjectileWaves", Value = 1 })
	SetProjectileProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "Scale", Value = 1 })
	SetProjectileProperty({ WeaponName = "BowWeaponDash", DestinationId = CurrentRun.Hero.ObjectId, Property = "ExtentScale", Value = 1 })
	SetWeaponProperty({ WeaponName = "RushWeapon", DestinationId = CurrentRun.Hero.ObjectId, Property = "FireGraphic", Value = "ZagreusDashNoCollide" })
	SetWeaponProperty({ WeaponName = "RushWeapon", DestinationId = CurrentRun.Hero.ObjectId, Property = "PostBlinkAnim", Value = "null" })
	CurrentRun.CurrentRoom.ChargeTicksReached = 0
end

ModUtil.Path.Context.Wrap("DoBowChargeX",function()
	ModUtil.Path.Wrap("SetProjectileProperty",function(baseFunc, args)
		baseFunc(args)
		if args.WeaponName == "BowWeapon" then 
			args.WeaponName = "BowWeaponDash"
			baseFunc(args)
		end
		return
	end)
end)
	
ModUtil.Path.Context.Wrap("EmptyBowChargeX",function()
	ModUtil.Path.Wrap("SetWeaponProperty",function(baseFunc, args)
		baseFunc(args)
		if args.WeaponName == "BowWeapon" then 
			args.WeaponName = "BowWeaponDash"
			baseFunc(args)
		end
		return
	end)
end)

ModUtil.Path.Context.Wrap("EmptyBowChargeX",function()
	ModUtil.Path.Wrap("SetProjectileProperty",function(baseFunc, args)
		baseFunc(args)
		if args.WeaponName == "BowWeapon" then 
			args.WeaponName = "BowWeaponDash"
			baseFunc(args)
		end
		return
	end)
end)
]]
--make dash while charging work with standing attack (TODO -- check if this is eating dash strikes, maybe add stupid hermes code)
ModUtil.Path.Wrap("DashManeuver", function(baseFunc, duration)
	if CurrentRun.CurrentRoom.BowCharging then
		return
	end
	return baseFunc(duration)
end)

--put back commented out beam bow modifications (mostly cool graphics stuff instead of boring arrows)
local beamBowComments = {
			{

				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "Type",
				ChangeValue = "BEAM",
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "MultiDetonate",
				ChangeValue = true,
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "DrawAsBeam",
				ChangeValue = true,
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "GroupName",
				ChangeValue = "Standing",
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "TipFx",
				ChangeValue = "DemeterLaserTipFlare",
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

						{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "Graphic",
				ChangeValue = "DemeterLaser",
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "Fuse",
				ChangeValue = 0.2,
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},

			{
				WeaponNames = { "BowWeapon", "BowWeaponDash" },
				ProjectileProperty = "TotalFuse",
				ChangeValue = 0.4,
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},
			--RNG damage fix

			{
				WeaponNames = { "BowSplitShot" },
				ProjectileProperty = "DamageHigh",
				ChangeValue = 70,
				ChangeType = "Absolute",
				ExcludeLinked = true,
			},


}
--remove buggy random damage thing
table.remove(TraitData.BowBeamTrait.PropertyChanges)

for key, fix in pairs(beamBowComments) do
	table.insert(TraitData.BowBeamTrait.PropertyChanges,fix)
end
