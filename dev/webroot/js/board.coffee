margin = 20
size = 40
count = 12
height = Math.ceil 2*margin+(3*count+1)/2*size
width = 2*margin+Math.ceil(Math.sqrt(3)*size/2)*25

hitOptions =
    segments: true
    stroke: true
    fill: true
    tolerance: 2

view.viewSize = [width,height]

#onMouseDown = (event) ->
    #path = new Path()
    #path.strokeColor = '#00000'
    #path.selected = true

    #path.add event.point

#onMouseDrag = (event) ->
    #step = event.delta
    #step.angle += 90

    #top = event.middlePoint + step
    #bottom = event.middlePoint - step
    
    #line = new Path()
    #line.strokeColor = '#000000'
    #line.add top
    #line.add bottom

    #path.add top
    #path.insert 0, bottom

onMouseMove = (event) ->
    hitResult = project.hitTest event.point, hitOptions
    project.activeLayer.selected = false
    if hitResult and hitResult.item
        hitResult.item.selected = true

drawHex = (x, y, size) ->
    hex = new Path.RegularPolygon new Point(x, y), 6, size
    hex.style =
        fillColor: new RgbColor 0, 0, 0, 0
        strokeColor: 'yellow'
        strokeWidth: 3
        selected: false
    glow hex, strokeColor: 'yellow', strokeWidth: 10

glow = (path, glow) ->
    glow = glow || {}
    s =
        strokeWidth: (glow.strokeWidth || 10) + path.strokeWidth
        fillColor: glow.fillColor || new RgbColor 0, 0, 0, 0
        opacity: glow.opacity || .5
        translatePoint: glow.translatePoint || new Point 0, 0
        strokeColor: glow.strokeColor || "#000"

    c = s.strokeWidth / 2
    out = []
    for i in [1..c+1]
        newPath = path.clone()
        newPath.style =
            strokeColor: s.strokeColor 
            fillColor: s.fillColor
            strokeJoin: "round"
            strokeCap: "round"
            strokeWidth: +(s.strokeWidth / c * i).toFixed(3)
        newPath.strokeColor.alpha = +(s.opacity / c).toFixed(3)
        newPath.moveBelow path
        out.push newPath
    out

horIncrement = Math.ceil Math.sqrt(3)*size
verIncrement = Math.ceil 3*size/2
offset = false

for y in [margin + size..height-margin-size] by verIncrement
    for x in [(margin + horIncrement/2 + (if offset then horIncrement/2 else 0))..width - margin - (if not offset then horIncrement/2 else 0)] by horIncrement
        drawHex x, y, size
    offset = not offset

path = new Path()
start = new Point margin + size, size + margin
end = new Point margin + size + horIncrement, margin+size+2*verIncrement
path.add start
path.lineTo end
path.strokeColor = '#0000ff'
path.strokeWidth = 2
glow path, strokeColor: '#0000ff', strokeWidth: 8
size = new Size 10, 8
point = path.getPointAt 0
rectangle = new Rectangle point, size
oval = new Path.Oval rectangle
oval.fillColor = '#0000ff'
oval.position += new Point(-5, -4)
glowPaths = glow oval, strokeColor: '#0000ff', strokeWidth: 10

direction = end - start
onFrame = (event) ->
    if oval.position.x > end.x and oval.position.y > end.y or oval.position.x < start.x and oval.position.y < start.y
        direction = -direction
    oval.position += direction/50
    glowPaths.forEach (v, i, all) ->
        v.position += direction/50
