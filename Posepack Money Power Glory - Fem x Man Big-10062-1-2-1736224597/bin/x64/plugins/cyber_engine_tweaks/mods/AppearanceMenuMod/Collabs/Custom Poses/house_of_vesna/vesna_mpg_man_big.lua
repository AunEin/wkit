-- #######################################
-- #######################################
-- #######################################
-- House of Vesna:  Money Power Glory Pose Pack (2023) (2023)
--
-- Credits: https://linktr.ee/CyberVesna
--
-- Do not reupload.
-- #######################################
-- #######################################
-- #######################################


return {
  -- Your beautiful name :)
  modder = "Vesna",
  
  -- A custom category for your poses that will appear on the list in the tab. 
  -- You could use your name or a description of your pose pack. 
  -- You can also add your stuff to a category that somebody else has already defined.
  category = "HoV: Money Power Glory [MAN BIG]",
  
  -- relative path to your ent file. You can copy this from Wolvenkit.
  -- Don't forget to add the extra slashes!
  entity_path = "vesna_mpg_m\\controller\\ves_mpg_male.ent",
  
  -- Your animations. The list is ordered by rig, as AMM needs this information to filter.
  -- You can remove entries you aren't using, but don't change any of the keys (the thing in the [brackets]). 
  -- Each list contains animation names. The string must be identical and is used in your .anims file, 
  -- during Blender export, and in the .workspot file, where everything is connected.
  anims = {        
      ["Man Average"] = {},                                    
      ["Big"] = {"ves_mpg_male_1",
        "ves_mpg_male_2",
        "ves_mpg_male_3",
        "ves_mpg_male_4",
        "ves_mpg_male_5",
        "ves_mpg_male_6",
        "ves_mpg_male_7",
        "ves_mpg_male_8",
        "ves_mpg_male_9",
        "ves_mpg_male_10",
        "ves_mpg_male_11",
        "ves_mpg_male_12",
        "ves_mpg_male_13",
        "ves_mpg_male_14",
        "ves_mpg_male_15",
        "ves_mpg_male_16",
        "ves_mpg_male_17",
        "ves_mpg_male_18",
        "ves_mpg_male_19",
        "ves_mpg_male_20",
        "ves_mpg_male_21",
        "ves_mpg_male_22",
        "ves_mpg_male_23",
        "ves_mpg_male_24",
        "ves_mpg_male_25"
      },                             -- any body gender: big folks, e.g. Jackie, River, Rhino…
      ["Child"] = {},                           -- any body gender: children
      ["Fat"] = {},                             -- any body gender: fat tolks, e.g. Dexter
      ["Man Massive"] = {},                     -- Smasher      
      ["Player Man"] = {},                      -- first person: male body gender V
      ["Player Woman"] = {},                    -- first person: maleale body gender V
  }
}