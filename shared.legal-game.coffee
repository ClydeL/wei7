class LegalGame extends Game
    constructor: (size, @komi) ->
        super(size, Game.COLOR_BLACK)
        @_isEnded = false
    playMove: (position) ->
        if @_isEnded then fail("Game already ended.")
        move = {color: @getNextColor(), position: position}
        lastMove = @getLastMove()
        lastButOneMove = if @moves.length < 2 then null else @moves[@moves.length - 2]
        super(move)
        # 禁止打劫时立即反吃
        do =>
            if lastMove != null and lastMove.captures.length == 1 == move.captures.length
                p11 = lastMove.position
                p12 = lastMove.captures[0]
                p21 = move.position
                p22 = move.captures[0]
                p11p21 = p11.vectorToTarget(p21)
                p11p12 = p11.vectorToTarget(p12)
                p21p22 = p21.vectorToTarget(p22)
                if p11p21.magnitude() == 1 and p11p21.equal(p11p12) and p11p12.oppositeTo(p21p22)
                    @undo()
                    fail("Illegal move.")
        # 禁止“送二还一”，因其可能被用于耍赖（故意导致无法终局）
        do =>
            if lastButOneMove != null and
                    lastButOneMove.captures.length == 0 and
                    lastMove.captures.length == 2 and
                    move.captures.length == 1
                p11 = lastButOneMove.position
                p21 = lastMove.position
                p22 = lastMove.captures[0]
                p23 = lastMove.captures[1]
                p31 = move.position
                p32 = move.captures[0]
                p11p21 = p11.vectorToTarget(p21)
                p21p31 = p21.vectorToTarget(p31)
                p21p22 = p21.vectorToTarget(p22)
                p21p23 = p21.vectorToTarget(p23)
                p31p32 = p31.vectorToTarget(p32)
                if p11p21.magnitude() == 2 and p21p31.magnitude() == 1 and
                    p11p21.directionInDegreesTo(p21p31) == 180 and (
                        (p22.equal(p11) and p21p22.equal(p21p23.multiply(2))) or
                        (p23.equal(p11) and p21p23.equal(p21p22.multiply(2)))
                    ) and p32.equal(p21)
                        @undo()
                        fail("Illegal move.")
        if lastMove != null and lastMove.position == null and move.position == null
            @_isEnded = true
    setResult: (winner, margin) ->
        if @_result != undefined then fail("Game result already set.")
        @_isEnded = true
        @_result = {winner: winner, margin: margin}
    getResult: ->
        if @_result == undefined
            undefined
        else
            {winner: @_result.winner, margin: @_result.margin}
    end: -> @_isEnded = true
    isEnded: -> @_isEnded
    resign: -> @setResult(Game.getOpposite(@getNextColor()), null)
    calculateScore: ->
        seeableColor = (point, unitDirection) =>
            p = point
            loop
                p = p.add(unitDirection)
                if not (0 <= p.x < @size and 0 <= p.y < @size) then return null
                color = @getColor(p)
                if color != Game.COLOR_EMPTY then return color
        blackScore = 0
        whiteScore = 0
        for color, i in @getBoardSnapshot()
            if color == Game.COLOR_BLACK
                blackScore++
            else if color == Game.COLOR_WHITE
                whiteScore++
            else
                p = @convertIndexToPoint(i)
                seeableColors = [
                    seeableColor(p, new Point(1, 0))
                    seeableColor(p, new Point(-1, 0))
                    seeableColor(p, new Point(0, 1))
                    seeableColor(p, new Point(0, -1))
                ]
                if seeableColors.some((m) -> m == Game.COLOR_BLACK) and
                        seeableColors.every((m) -> m != Game.COLOR_WHITE)
                    blackScore++
                else if seeableColors.some((m) -> m == Game.COLOR_WHITE) and
                        seeableColors.every((m) -> m != Game.COLOR_BLACK)
                    whiteScore++
                else
                    blackScore += 0.5
                    whiteScore += 0.5
        blackMargin = blackScore - whiteScore - @komi
        black: blackScore
        white: whiteScore
        winner:
            if blackMargin > 0
                Game.COLOR_BLACK
            else if blackMargin < 0
                Game.COLOR_WHITE
            else
                null
        margin: Math.abs(blackMargin)