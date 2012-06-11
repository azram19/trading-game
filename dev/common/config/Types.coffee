Types =
    Entities:
        Channel: 1
        Signal: 2
        Player: 3
        Platforms:
          HQ: 4
          Normal: 5
    Resources:
        Metal: 6
        Tritium: 7
        Names: [
            "Metal"
            "Tritium"
        ]
        Amounts: [
            100
            100
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
      Team:
        Side2: 5
        Side3: 6
        Side4: 7
      Info:
        0:
          name: 'Deathmatch'
          numberOfSides: 2
          playersOnASide: 1
          minWidth: 8
          maxWidth: 15
          startingPoints: [[2,2],[6,12]]
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
        5:
          name: 'Team Match'
          numberOfSides: 2
          playersOnASide: 2
          teams: true
        6:
          name: 'Team Match'
          numberOfSides: 2
          playersOnASide: 3
          teams: true
        7:
          name: 'Team Match'
          numberOfSides: 2
          playersOnASide: 4
          teams: true

if module? and module.exports
  exports = module.exports = Types
else
  window.S.Types = Types
