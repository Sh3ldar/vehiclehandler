return {
    ['cleankit'] = {
        label = "Cleaning vehicle",
        duration = math.random(10000, 20000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
        },
    },
    ['smallkit'] = {
        label = "Repairing vehicle",
        duration = math.random(15000, 20000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "mini@repair",
            clip = "fixing_a_player"
        },
    },
    ['bigkit'] = {
        label = "Repairing vehicle",
        duration = math.random(25000, 30000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "mini@repair",
            clip = "fixing_a_player"
        },
    }
}