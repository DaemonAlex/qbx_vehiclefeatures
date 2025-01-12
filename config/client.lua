return {
    pedVisible = true, -- If true you can see the player inside the vehicle boot.
    canCamMove = true, -- Allows the camera to move around the vehicle with a small radius for zooming in/out.
    barPeeking = true, -- Adds 2 bars top and bottom so you have a peeking effect.
    enableRadialMenu = true, -- Enable or disable all radial menu options.
    enableSeatsMenu = true, -- Enable or disable the vehicle seat switch radial menu option.
    enableWindowsMenu = true, -- Enable or disable the vehicle windows radial menu option.
    enableExtraMenu = true, -- Enable or disable the vehicle extras radial menu option.
    enableDoorsMenu = true, -- Enable or disable the vehicle doors radial menu option.
    enableFlipMenu = true, -- Enable or disable the vehicle flip radial menu option.
    enablePushMenu = true, -- Enable or disable the vehicle push radial menu option.
    enableTrunkMenu = true, -- Enable or disable the trunk hide/kidnap radial menu options.
    enableTargets = true, -- Enable or disable all target options.
    enableFlipTarget = true, -- Enable or disable the vehicle flip target option.
    enablePushTarget = true, -- Enable or disable the vehicle push target option.
    enableTrunkTarget = true, -- Enable or disable the trunk hide/kidnap target options.
    drawText3dTrunk = true, -- Enable or disable the drawText3d for showing how to open and exit the trunk.
    flipVehicleTime = 15000, -- Time it takes to flip a vehicle.
    allowedSeatSpeed = 100.0, -- Switching seats while driving under the set kmh is allowed.
    allowedTrunkSpeed = 50.0, -- Jumping out the trunk while driving under the set kmh is allowed.
    customOffset = { -- Most vehicles do not need custom offsets, but there are vehicles with lower boots.
        [`coquette3`] = {
            leftOffset = 0.0,
            backOffset = 0.0,
            heightOffset = -0.02
        },
        [`coquette5`] = {
            leftOffset = 0.0,
            backOffset = 0.2,
            heightOffset = -0.05
        },
        [`chino`] = {
            leftOffset = 0.0,
            backOffset = 0.4,
            heightOffset = -0.05
        },
        [`blista`] = {
            leftOffset = 0.0,
            backOffset = -0.1,
            heightOffset = -0.3
        },
        [`glendale`] = {
            leftOffset = 0.0,
            backOffset = -0.2,
            heightOffset = -0.35
        },
    },
    visualItemsInTrunk = true, -- Allow visual items in the trunk if someone puts an item in the trunk stash.
    defaultTrunkItem = `prop_cs_cardbox_01`, -- The default item used in the trunk if no trunkModels are found.
    trunkItemSlots = { -- You could add more if you want more visual items inside of the trunk, current positions are based on default item.
        [1] = {
            leftOffset = -0.1,
            backOffset = 0.0,
            heightOffset = 0.0
        },
        [2] = {
            leftOffset = 0.33,
            backOffset = 0.0,
            heightOffset = 0.0
        }
    },
    trunkModels = { -- Set which items are visual besides the default one, these items have priority as does the threshold.
        {
            key = 'money',
            data = {
                {
                    threshold = 1,
                    model = `h4_prop_h4_cash_stack_02a`,
                    pitchOffset = 0.0,
                    RollOffset = 0.0,
                    yawOffset = 0.0,
                },
                {
                    threshold = 500,
                    model = `h4_prop_h4_cash_stack_01a`,
                    pitchOffset = 0.0,
                    RollOffset = 0.0,
                    yawOffset = 0.0,
                }
            }
        },
        {
            key = 'coke_brick',
            data = {
                {
                    threshold = 1,
                    model = `bkr_prop_coke_cutblock_01`,
                    pitchOffset = 0.0,
                    RollOffset = 0.0,
                    yawOffset = 0.0,
                },
                {
                    threshold = 5,
                    model = `bkr_prop_coke_block_01a`,
                    pitchOffset = 0.0,
                    RollOffset = 0.0,
                    yawOffset = 0.0,
                    ignoreTrunkSlots = true, -- Ignore trunkItemSlots (model will be center)
					heightOffset = -0.1 -- Some models might be a bit large try to ignore those.
                }
            }
        }
    },
    trunkDisabled = { -- Add any vehicle that is not allowed to hide inside the boot.
        `penetrator`,
        `vacca`,
        `monroe`,
        `turismor`,
        `osiris`,
        `comet`,
        `ardent`,
        `jester`,
        `nero`,
        `nero2`,
        `vagner`,
        `infernus`,
        `zentorno`,
        `comet2`,
        `comet3`,
        `comet4`,
        `bullet`,
        `adder`
    },
    classDisabled = { -- Disable any vehicle class if needed where it is not allowed to hide inside the boot.
        [0] = false, -- Coupes
        [1] = false, -- Sedans
        [2] = false, -- SUVs
        [3] = false, -- Coupes
        [4] = false, -- Muscle
        [5] = false, -- Sports Classics
        [6] = false, -- Sports
        [7] = false, -- Super
        [8] = true, -- Motorcycles
        [9] = false, -- Off-road
        [10] = false, -- Industrial
        [11] = false, -- Utility
        [12] = false, -- Vans
        [13] = false, -- Cycles
        [14] = false, -- Boats
        [15] = false, -- Helicopters
        [16] = false, -- Planes
        [17] = false, -- Service
        [18] = false, -- Emergency
        [19] = false, -- Military
        [20] = false, -- Commercial
        [21] = false -- Trains
    },
}