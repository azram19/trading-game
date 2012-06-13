Types =
    UI:
      Size: 45
      Margin: 150
    Entities:
      Channel: 1
      Signal: 2
      Player: 3
      Platforms:
        HQ: 4
        Normal: 5
    Terrain:
      Water: 1
      Sand: 2
      Dirt: 3
      Rocks: 4
      Deepwater: 5
      Grass: 6
      Snow: 7
      Names: [
        "water"
        "sand"
        "dirt"
        "rocks"
        "deepwater"
        "grass"
        "snow"
      ]
    Resources:
        Gold: 6
        Food: 7
        Resources: 8
        Names: [
            "Gold"
            "Food"
            "Resources"
        ]
        Amounts: [
            200
            300
            100
        ]
        Lifes: [
            -> (Math.random() * 1000 % 760) + 100
            -> (Math.random() * 2000 % 1260) + 300
            -> (Math.random() * 1000 % 560) + 400
        ]
    Events:
      Routing:
        title: 'set routing'
      Build:
        title: 'build'
        Channel:
          title: 'channel'
        Platform:
          title: 'platform'
          desc: 'build some platfrom'
    Games:
      FFA:
        Number2: 0
        Number3: 1
        Number4: 2
        Number5: 3
        Number6: 4
      Info:
        0:
          name: 'Deathmatch'
          numberOfSides: 2
          playersOnASide: 1
          minWidth: 8
          maxWidth: 15
          startingPoints: [[2,2],[7,12]]
          teams: false
        1:
          name: 'Deathmatch'
          numberOfSides: 3
          playersOnASide: 1
          teams: false
        2:
          name: 'Deathmatch'
          numberOfSides: 4
          playersOnASide: 1
          teams: false
        3:
          name: 'Deathmatch'
          numberOfSides: 5
          playersOnASide: 1
          teams: false
        4:
          name: 'Deathmatch'
          numberOfSides: 6
          playersOnASide: 1
          teams: false

if module? and module.exports
  exports = module.exports = Types
else
  window.S.Types = Types
