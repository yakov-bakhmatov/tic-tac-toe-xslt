<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
    <xsl:param name="param"/>
  
    <xsl:template match="/">
        <game>
            <xsl:variable name="input_errors">
                <xsl:call-template name="validate_input"/>
            </xsl:variable>
            <xsl:variable name="state">
                <xsl:call-template name="get_board_state">
                    <xsl:with-param name="board" select="/game/board"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$state != ''">
                    <!-- принудительный сброс -->
                    <xsl:call-template name="reset_board"/>
                </xsl:when>
                <xsl:when test="$input_errors = ''">
                    <xsl:choose>
                        <xsl:when test="$param = 'r'">
                            <xsl:call-template name="reset_board"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="do_move"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <board>
                        <xsl:value-of select="/game/board"/>
                    </board>
                    <message><xsl:value-of select="$input_errors"/></message>
                    <beginner><xsl:value-of select="/game/beginner"/></beginner>
                </xsl:otherwise>
            </xsl:choose>
        </game>
    </xsl:template>
  
    <xsl:template name="validate_input">
        <xsl:choose>
            <xsl:when test="$param = 'r'">
                <!-- начать сначала -->
            </xsl:when>
            <xsl:when test="$param = '1' or
                            $param = '2' or
                            $param = '3' or
                            $param = '4' or
                            $param = '5' or
                            $param = '6' or
                            $param = '7' or
                            $param = '8' or
                            $param = '9'">
                <!-- проверить, что клетка свободна -->
                <xsl:if test="substring(/game/board/text(), number($param), 1) != $param">
                    <xsl:text>Эта клетка уже занята! Повтори.</xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Ты что-то не то ввёл. Повтори.</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="reset_board">
        <xsl:choose>
            <xsl:when test="/game/beginner = 'O'">
                <board>123456789</board>
                <message>Давай начнём с начала. Ты ходишь первым.</message>
                <beginner>X</beginner>
            </xsl:when>
            <xsl:otherwise>
                <board>1234O6789</board>
                <message>Давай начнём с начала. Теперь я хожу первым. Как всегда, в центр.</message>
                <beginner>O</beginner>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="do_move">
        <xsl:variable name="board_after_human_move">
            <xsl:call-template name="apply_move">
                <xsl:with-param name="board" select="/game/board"/>
                <xsl:with-param name="player" select="'X'"/>
                <xsl:with-param name="position" select="$param"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="state_after_human_move">
            <xsl:call-template name="get_board_state">
                <xsl:with-param name="board" select="$board_after_human_move"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$state_after_human_move = ''">
                <xsl:variable name="board_after_computer_move">
                    <xsl:call-template name="make_computer_move">
                        <xsl:with-param name="board" select="$board_after_human_move"/>
                    </xsl:call-template>
                </xsl:variable>
                <board>
                    <xsl:value-of select="$board_after_computer_move"/>
                </board>
                <state>
                    <xsl:call-template name="get_board_state">
                        <xsl:with-param name="board" select="$board_after_computer_move"/>
                    </xsl:call-template>
                </state>
            </xsl:when>
            <xsl:otherwise>
                <board>
                    <xsl:value-of select="$board_after_human_move"/>
                </board>
                <state>
                    <xsl:value-of select="$state_after_human_move"/>
                </state>
            </xsl:otherwise>
        </xsl:choose>
        <beginner><xsl:value-of select="/game/beginner"/></beginner>
    </xsl:template>

    <xsl:template name="apply_move">
        <xsl:param name="board"/>
        <xsl:param name="player"/>
        <xsl:param name="position"/>
        <xsl:value-of select="translate($board, string($position), $player)"/>
    </xsl:template>

    <xsl:template name="get_board_state">
        <xsl:param name="board"/>
        <xsl:variable name="winner">
            <xsl:call-template name="get_winner">
                <xsl:with-param name="board" select="$board"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="game_is_over">
            <xsl:call-template name="is_over">
                <xsl:with-param name="board" select="$board"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string($winner) != ''">
                <xsl:value-of select="$winner"/>
            </xsl:when>
            <xsl:when test="string($game_is_over) = 'game-is-over'">
                <xsl:text>tie</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get_winner">
        <xsl:param name="board"/>
        <!--
            1 2 3
            4 5 6
            7 8 9
        -->
        <xsl:choose>
            <!-- строки -->
            <xsl:when test="substring($board, 1, 1) = substring($board, 2, 1) and
                            substring($board, 2, 1) = substring($board, 3, 1)">
                <xsl:value-of select="substring($board, 1, 1)"/>
            </xsl:when>
            <xsl:when test="substring($board, 4, 1) = substring($board, 5, 1) and
                            substring($board, 5, 1) = substring($board, 6, 1)">
                <xsl:value-of select="substring($board, 4, 1)"/>
            </xsl:when>
            <xsl:when test="substring($board, 7, 1) = substring($board, 8, 1) and
                            substring($board, 8, 1) = substring($board, 9, 1)">
                <xsl:value-of select="substring($board, 7, 1)"/>
            </xsl:when>
            <!-- столбцы -->
            <xsl:when test="substring($board, 1, 1) = substring($board, 4, 1) and
                            substring($board, 4, 1) = substring($board, 7, 1)">
                <xsl:value-of select="substring($board, 1, 1)"/>
            </xsl:when>
            <xsl:when test="substring($board, 2, 1) = substring($board, 5, 1) and
                            substring($board, 5, 1) = substring($board, 8, 1)">
                <xsl:value-of select="substring($board, 2, 1)"/>
            </xsl:when>
            <xsl:when test="substring($board, 3, 1) = substring($board, 6, 1) and
                            substring($board, 6, 1) = substring($board, 9, 1)">
                <xsl:value-of select="substring($board, 3, 1)"/>
            </xsl:when>
            <!-- диагонали -->
            <xsl:when test="substring($board, 1, 1) = substring($board, 5, 1) and
                            substring($board, 5, 1) = substring($board, 9, 1)">
                <xsl:value-of select="substring($board, 1, 1)"/>
            </xsl:when>
            <xsl:when test="substring($board, 3, 1) = substring($board, 5, 1) and
                            substring($board, 5, 1) = substring($board, 7, 1)">
                <xsl:value-of select="substring($board, 3, 1)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="is_over">
        <xsl:param name="board"/>
        <xsl:if test="translate($board, 'XO', '') = ''">
            <xsl:text>game-is-over</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template name="make_computer_move">
        <xsl:param name="board"/>
        <!-- make_computer_move_decision_tree -->
        <!-- make_computer_move_minimax -->
        <xsl:call-template name="make_computer_move_minimax">
            <xsl:with-param name="board" select="$board"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="make_computer_move_minimax">
        <xsl:param name="board"/>
        <xsl:variable name="position">
            <xsl:call-template name="get_the_best_move">
                <xsl:with-param name="board" select="$board"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="apply_move">
            <xsl:with-param name="board" select="$board"/>
            <xsl:with-param name="player" select="'O'"/>
            <xsl:with-param name="position" select="$position"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="get_the_best_move">
        <xsl:param name="board"/>
        <xsl:call-template name="get_the_best_move_loop">
            <xsl:with-param name="board" select="$board"/>
            <xsl:with-param name="index" select="1"/>
            <xsl:with-param name="position" select="1"/>
            <xsl:with-param name="score" select="-1000"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="get_the_best_move_loop">
        <xsl:param name="board"/>
        <xsl:param name="index"/>
        <xsl:param name="position"/>
        <xsl:param name="score"/>
        <xsl:choose>
            <xsl:when test="number($index) &gt; 9">
                <!-- конец цикла -->
                <xsl:value-of select="$position"/>
            </xsl:when>
            <xsl:when test="substring($board, number($index), 1) = string($index)">
                <!-- если клетка свободна, вычисляем её оценку -->
                <xsl:variable name="new_board">
                    <xsl:call-template name="apply_move">
                        <xsl:with-param name="board" select="$board"/>
                        <xsl:with-param name="player" select="'O'"/>
                        <xsl:with-param name="position" select="$index"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="new_score">
                    <xsl:call-template name="minimax">
                        <xsl:with-param name="board" select="$new_board"/>
                        <xsl:with-param name="player" select="'X'"/>
                        <xsl:with-param name="depth" select="0"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="number($score) &lt; number($new_score)">
                        <!-- если у текущей клетки лучшая оценка, запоминаем её -->
                        <xsl:call-template name="get_the_best_move_loop">
                            <xsl:with-param name="board" select="$board"/>
                            <xsl:with-param name="index" select="number($index) + 1"/>
                            <xsl:with-param name="position" select="number($index)"/>
                            <xsl:with-param name="score" select="number($new_score)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get_the_best_move_loop">
                            <xsl:with-param name="board" select="$board"/>
                            <xsl:with-param name="index" select="number($index) + 1"/>
                            <xsl:with-param name="position" select="$position"/>
                            <xsl:with-param name="score" select="$score"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- иначе переход на следующую клетку -->
                <xsl:call-template name="get_the_best_move_loop">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="index" select="number($index) + 1"/>
                    <xsl:with-param name="position" select="$position"/>
                    <xsl:with-param name="score" select="$score"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="minimax">
        <xsl:param name="board"/>
        <xsl:param name="player"/>
        <xsl:param name="depth"/>
        <xsl:variable name="state">
            <xsl:call-template name="get_board_state">
                <xsl:with-param name="board" select="$board"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$state = 'X'">
                <xsl:value-of select="-10 + number($depth)"/>
            </xsl:when>
            <xsl:when test="$state = 'O'">
                <xsl:value-of select="10 - number($depth)"/>
            </xsl:when>
            <xsl:when test="$state = 'tie'">
                <xsl:value-of select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="score">
                    <xsl:choose>
                        <xsl:when test="$player = 'X'">
                            <xsl:value-of select="1000"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="-1000"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:call-template name="minimax_loop">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="player" select="$player"/>
                    <xsl:with-param name="depth" select="$depth"/>
                    <xsl:with-param name="index" select="1"/>
                    <xsl:with-param name="score" select="$score"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="minimax_loop">
        <xsl:param name="board"/>
        <xsl:param name="player"/>
        <xsl:param name="depth"/>
        <xsl:param name="index"/>
        <xsl:param name="score"/>
        <xsl:choose>
            <xsl:when test="number($index) &gt; 9">
                <!-- конец цикла -->
                <xsl:value-of select="$score"/>
            </xsl:when>
            <xsl:when test="substring($board, number($index), 1) = string($index)">
                <!-- если клетка свободна, вычисляем её оценку -->
                <xsl:variable name="new_board">
                    <xsl:call-template name="apply_move">
                        <xsl:with-param name="board" select="$board"/>
                        <xsl:with-param name="player" select="$player"/>
                        <xsl:with-param name="position" select="$index"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="new_score">
                    <xsl:call-template name="minimax">
                        <xsl:with-param name="board" select="$new_board"/>
                        <!-- смена игрока: X -> O, O -> X -->
                        <xsl:with-param name="player" select="translate(string($player), 'XO', 'OX')"/>
                        <xsl:with-param name="depth" select="number($depth) + 1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="the_best_score">
                    <xsl:choose>
                        <xsl:when test="$player = 'X'">
                            <xsl:choose>
                                <xsl:when test="number($new_score) &lt; number($score)">
                                    <xsl:value-of select="number($new_score)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="number($score)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="number($new_score) &gt; number($score)">
                                    <xsl:value-of select="number($new_score)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="number($score)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:call-template name="minimax_loop">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="player" select="$player"/>
                    <xsl:with-param name="depth" select="$depth"/>
                    <xsl:with-param name="index" select="number($index) + 1"/>
                    <xsl:with-param name="score" select="$the_best_score"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- иначе переход на следующую клетку -->
                <xsl:call-template name="minimax_loop">
                    <xsl:with-param name="board" select="$board"/>
                    <xsl:with-param name="player" select="$player"/>
                    <xsl:with-param name="depth" select="$depth"/>
                    <xsl:with-param name="index" select="number($index) + 1"/>
                    <xsl:with-param name="score" select="$score"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
