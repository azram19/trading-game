Types =
    Entities:
        HQ: 1
        Platform: 2
        Channel: 3
        Signal: 4
        Player: 5
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
    Platforms:
        Normal: 8
        HQ: 9
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
      FFA: 0
      Team:
        Side1: 1
        Side2: 2
        Side3: 3
        Side4: 4

if module? and module.exports
  exports = module.exports = Types
else
  window.S.Types = Types
