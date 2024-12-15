return {
	pedVisible = true, -- If true you can see the player inside the vehicle boot.
	canCamMove = true, -- Allows the camera to move around the vehicle with a small radius for zooming in/out.
	barPeeking = false, -- Adds 2 bars top and bottom so you have a peeking effect.
	customOffset = { -- Most vehicles do not need custom offsets, but there are vehicles with lower boots.
		[`coquette5`] = {
			leftOffset = 0.0,
			backOffset = 0.2,
			heightOffset = -0.05
		},
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
		`bullet`
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