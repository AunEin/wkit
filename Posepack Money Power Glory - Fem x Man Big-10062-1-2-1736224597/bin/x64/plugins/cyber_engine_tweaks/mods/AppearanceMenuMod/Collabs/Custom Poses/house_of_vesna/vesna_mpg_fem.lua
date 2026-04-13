-- #######################################
-- #######################################
-- #######################################
-- House of Vesna: Money Power Glory Pose Pack (2023)
--
-- Credits: https://linktr.ee/CyberVesna
--
-- Do not reupload.
-- #######################################
-- #######################################
-- #######################################


return {
  modder = "Vesna",
  category = "HoV: Money Power Glory",
  entity_path = "vesna_mpg_f\\controller\\ves_mpg_fem.ent",
  
  -- Your animations. The list is ordered by rig, as AMM needs this information to filter.
  -- You can remove entries you aren't using, but don't change any of the keys (the thing in the [brackets]). 
  -- Each list contains animation names. The string must be identical and is used in your .anims file, 
  -- during Blender export, and in the .workspot file, where everything is connected.
  anims = {        
      ["Man Average"] = {                       -- male body gender, e.g. spawned masc V, Johnny, Viktor, Takemura…
      },                    
      ["Woman Average"] = {                     -- female body gender, e.g. spawned femme V, Panam, Judy, Mamá Welles…
        "ves_mpg_fem_1",
        "ves_mpg_fem_2",
        "ves_mpg_fem_3",
        "ves_mpg_fem_4",
        "ves_mpg_fem_5",
        "ves_mpg_fem_6",
        "ves_mpg_fem_7",
        "ves_mpg_fem_8",
        "ves_mpg_fem_9",
        "ves_mpg_fem_10",
        "ves_mpg_fem_11",
        "ves_mpg_fem_12",
        "ves_mpg_fem_13",
        "ves_mpg_fem_14",
        "ves_mpg_fem_15",
        "ves_mpg_fem_16",
        "ves_mpg_fem_17",
        "ves_mpg_fem_18",
        "ves_mpg_fem_19",
        "ves_mpg_fem_20",
        "ves_mpg_fem_21",
        "ves_mpg_fem_22",
        "ves_mpg_fem_23",
        "ves_mpg_fem_24",
        "ves_mpg_fem_25"
      
      },                   
      ["Big"] = {},                             -- any body gender: big folks, e.g. Jackie, River, Rhino…
      ["Child"] = {},                           -- any body gender: children
      ["Fat"] = {},                             -- any body gender: fat tolks, e.g. Dexter
      ["Man Massive"] = {},                     -- Smasher      
      ["Player Man"] = {},                      -- first person: male body gender V
      ["Player Woman"] = {},                    -- first person: female body gender V
  }
}