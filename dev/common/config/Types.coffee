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
      Names: [
        ''
        'Channel'
        'Signal'
        'Player'
        'HQ'
        'Platform'
      ]
    Terrain:
      Water: 1
      Sand: 2
      Dirt: 3
      Rocks: 4
      Deepwater: 5
      Grass: 6
      Snow: 7
      Names: [
        "Water"
        "Sand"
        "Dirt"
        "Rocks"
        "Deepwater"
        "Grass"
        "Snow"
      ]
    Resources:
        Gold: 6
        Food: 7
        Names: [
            "Gold"
            "Food"
        ]
        Amounts: [
            200
            300
        ]
        Lifes: [
            -> Math.round((Math.random() * 2000 % 760) + 500)
            -> Math.round((Math.random() * 4000 % 1260) + 300)
        ]
    Events:
      Routing:
        title: 'set routing'
      Build:
        title: 'build'
        Channel:
          title: 'channel'
          cost:
            Gold: 100
            Food: 40
        Platform:
          title: 'platform'
          cost:
            Gold: 400
            Food: 300

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

if module? and module.exports
  exports = module.exports = Types
else
  window.S.Types = Types
