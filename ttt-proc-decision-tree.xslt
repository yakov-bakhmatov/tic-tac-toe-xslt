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
                <xsl:choose>
                    <xsl:when test="string($board_after_computer_move) = 'error'">
                        <board>
                            <xsl:value-of select="$board_after_human_move"/>
                        </board>
                        <state>
                            <xsl:text>error</xsl:text>
                        </state>
                        <message>
                            <xsl:text>Но так нельзя! У меня все ходы записаны! Давай сначала.</xsl:text>
                        </message>
                    </xsl:when>
                    <xsl:otherwise>
                        <board>
                            <xsl:value-of select="$board_after_computer_move"/>
                        </board>
                        <state>
                            <xsl:call-template name="get_board_state">
                                <xsl:with-param name="board" select="$board_after_computer_move"/>
                            </xsl:call-template>
                        </state>
                    </xsl:otherwise>
                </xsl:choose>
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
        <xsl:call-template name="make_computer_move_decision_tree">
            <xsl:with-param name="board" select="$board"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="make_computer_move_decision_tree">
        <xsl:param name="board"/>
        <xsl:choose>
            <xsl:when test="$board = 'X23456789'"><xsl:text>X234O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX34O6789'"><xsl:text>XXO4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOXO6789'"><xsl:text>XXOXO6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXO4OX789'"><xsl:text>XXO4OXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXO4O6X89'"><xsl:text>XXOOO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOXX89'"><xsl:text>XXOOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOO6XX9'"><xsl:text>XXOOOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOO6X8X'"><xsl:text>XXOOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXO4O67X9'"><xsl:text>XXO4O6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXO4O678X'"><xsl:text>XXO4O6O8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4O6789'"><xsl:text>XOX4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6789'"><xsl:text>XOXXO67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OX789'"><xsl:text>XOX4OX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6X89'"><xsl:text>XOX4O6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O67X9'"><xsl:text>XOXOO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOOX7X9'"><xsl:text>XOXOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOO6XX9'"><xsl:text>XOXOOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOO67XX'"><xsl:text>XOXOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O678X'"><xsl:text>XOX4O67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23XO6789'"><xsl:text>X23XO6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX3XO6O89'"><xsl:text>XXOXO6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XXO6O89'"><xsl:text>XOXXO6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXOXO89'"><xsl:text>XOXXOXOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6O8X'"><xsl:text>XOXXO6OOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23XOXO89'"><xsl:text>X2OXOXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23XO6OX9'"><xsl:text>X2OXO6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23XO6O8X'"><xsl:text>X2OXO6O8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234OX789'"><xsl:text>XO34OX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OX789'"><xsl:text>XOX4OX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOX789'"><xsl:text>XO3XOX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXX89'"><xsl:text>XO34OXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OX7X9'"><xsl:text>XO34OXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXOX9'"><xsl:text>XOX4OXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OX78X'"><xsl:text>XO34OX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6X89'"><xsl:text>X23OO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX3OO6X89'"><xsl:text>XX3OOOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOO6X89'"><xsl:text>X2XOOOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OOXX89'"><xsl:text>XO3OOXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOOXX89'"><xsl:text>XOXOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OOXXX9'"><xsl:text>XO3OOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OOXX8X'"><xsl:text>XO3OOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO6XX9'"><xsl:text>X23OOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO6X8X'"><xsl:text>X23OOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O67X9'"><xsl:text>X23OO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX3OO67X9'"><xsl:text>XX3OOO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOO67X9'"><xsl:text>X2XOOO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OOX7X9'"><xsl:text>X2OOOX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX7X9'"><xsl:text>XXOOOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOXXX9'"><xsl:text>X2OOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOX7XX'"><xsl:text>X2OOOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO6XX9'"><xsl:text>X23OOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO67XX'"><xsl:text>X23OOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O678X'"><xsl:text>XO34O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O678X'"><xsl:text>XOX4O67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO678X'"><xsl:text>XO3XO67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OX78X'"><xsl:text>XO34OX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O6X8X'"><xsl:text>XO34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O67XX'"><xsl:text>XO34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X3456789'"><xsl:text>OX3456789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX456789'"><xsl:text>OXXO56789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOX6789'"><xsl:text>OXXOX6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXO5X789'"><xsl:text>OXXO5XO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXO56X89'"><xsl:text>OXXOO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOOXX89'"><xsl:text>OXXOOXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOO6XX9'"><xsl:text>OXXOOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOO6X8X'"><xsl:text>OXXOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXO567X9'"><xsl:text>OXXO56OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXO5678X'"><xsl:text>OXXO56O8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3X56789'"><xsl:text>OX3XO6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXO6789'"><xsl:text>OXXXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XOX789'"><xsl:text>OX3XOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6X89'"><xsl:text>OX3XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO67X9'"><xsl:text>OX3XO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X6789'"><xsl:text>OX34X67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4X67O9'"><xsl:text>OXX4X6OO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXX6OO9'"><xsl:text>OXXXX6OOO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4XXOO9'"><xsl:text>OXXOXXOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4X6OOX'"><xsl:text>OXXOX6OOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XX67O9'"><xsl:text>OX3XXO7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXO7O9'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXOXO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO7OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34XX7O9'"><xsl:text>OX3OXX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOXX7O9'"><xsl:text>OXXOXXOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OXXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OXX7OX'"><xsl:text>OX3OXXOOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X6XO9'"><xsl:text>OXO4X6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX6XO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X67OX'"><xsl:text>OXO4X67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX67OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XX7OX'"><xsl:text>OXOOXX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX345X789'"><xsl:text>OX345XO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX45XO89'"><xsl:text>OXXO5XO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3X5XO89'"><xsl:text>OX3XOXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOXO89'"><xsl:text>OXXXOXO8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XOXOX9'"><xsl:text>OXOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XOXO8X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34XXO89'"><xsl:text>OX3OXXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX345XOX9'"><xsl:text>OX3O5XOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX345XO8X'"><xsl:text>OX3O5XO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3456X89'"><xsl:text>OX34O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6X89'"><xsl:text>OXX4O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6X89'"><xsl:text>OX3XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXX89'"><xsl:text>OX34OXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6XX9'"><xsl:text>OX34O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X8X'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34567X9'"><xsl:text>OX34O67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O67X9'"><xsl:text>OXX4O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO67X9'"><xsl:text>OX3XO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OX7X9'"><xsl:text>OX34OX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6XX9'"><xsl:text>OX34O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O67XX'"><xsl:text>OX34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6OXX'"><xsl:text>OXXOO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6OXX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXOXX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX345678X'"><xsl:text>OX34O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O678X'"><xsl:text>OXX4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OOX8X'"><xsl:text>OXXOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OO7XX'"><xsl:text>OXXOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OX78X'"><xsl:text>OXO4OX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXX8X'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OX7XX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X8X'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O67XX'"><xsl:text>OX34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6OXX'"><xsl:text>OXXOO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6OXX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXOXX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X456789'"><xsl:text>12X4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4O6789'"><xsl:text>XOX4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6789'"><xsl:text>XOXXO67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OX789'"><xsl:text>XOX4OX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6X89'"><xsl:text>XOX4O6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O67X9'"><xsl:text>XOXOO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOOX7X9'"><xsl:text>XOXOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOO6XX9'"><xsl:text>XOXOOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOO67XX'"><xsl:text>XOXOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O678X'"><xsl:text>XOX4O67OX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XX4O6789'"><xsl:text>OXX4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXO6789'"><xsl:text>OXXXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OX789'"><xsl:text>OXX4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6X89'"><xsl:text>OXX4O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O67X9'"><xsl:text>OXX4O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O678X'"><xsl:text>OXX4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OOX8X'"><xsl:text>OXXOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OO7XX'"><xsl:text>OXXOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12XXO6789'"><xsl:text>O2XXO6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXO6789'"><xsl:text>OXXXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOX789'"><xsl:text>O2XXOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6X89'"><xsl:text>O2XXO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO67X9'"><xsl:text>O2XXO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO678X'"><xsl:text>O2XXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOOX8X'"><xsl:text>O2XXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO7XX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OX789'"><xsl:text>12X4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4OX78O'"><xsl:text>XOX4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXOX78O'"><xsl:text>XOXXOX7OO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXX8O'"><xsl:text>XOX4OXXOO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OX7XO'"><xsl:text>XOXOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XX4OX78O'"><xsl:text>OXX4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = '12XXOX78O'"><xsl:text>O2XXOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OXX8O'"><xsl:text>O2X4OXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OX7XO'"><xsl:text>O2X4OX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6X89'"><xsl:text>1OX4O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6X89'"><xsl:text>XOX4O6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6X89'"><xsl:text>1OXXO6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXX89'"><xsl:text>1OX4OXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4O6XX9'"><xsl:text>1OX4O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6XXO'"><xsl:text>XOXOO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6XXO'"><xsl:text>OOXXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXXXO'"><xsl:text>OOX4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4O6X8X'"><xsl:text>1OX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O67X9'"><xsl:text>12XOO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOO67X9'"><xsl:text>X2XOOO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = '1XXOO67X9'"><xsl:text>1XXOOO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = '12XOOX7X9'"><xsl:text>12XOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOOX7XO'"><xsl:text>XOXOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XXOOX7XO'"><xsl:text>OXXOOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '12XOOXXXO'"><xsl:text>O2XOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '12XOO6XX9'"><xsl:text>12XOOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = '12XOO67XX'"><xsl:text>12XOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O678X'"><xsl:text>12X4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4OO78X'"><xsl:text>X2XOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XX4OO78X'"><xsl:text>1XXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = '12XXOO78X'"><xsl:text>O2XXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOOX8X'"><xsl:text>O2XXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO7XX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OOX8X'"><xsl:text>12XOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OO7XX'"><xsl:text>12XOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '123X56789'"><xsl:text>O23X56789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3X56789'"><xsl:text>OX3XO6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXO6789'"><xsl:text>OXXXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XOX789'"><xsl:text>OX3XOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6X89'"><xsl:text>OX3XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO67X9'"><xsl:text>OX3XO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XX56789'"><xsl:text>O2XXO6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXO6789'"><xsl:text>OXXXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOX789'"><xsl:text>O2XXOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6X89'"><xsl:text>O2XXO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO67X9'"><xsl:text>O2XXO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO678X'"><xsl:text>O2XXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOOX8X'"><xsl:text>O2XXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO7XX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XX6789'"><xsl:text>O23XXO789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO789'"><xsl:text>OX3XXO7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXO7O9'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXOXO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO7OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXO789'"><xsl:text>O2XXXOO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXOO89'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOOX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOO8X'"><xsl:text>OOXXXOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXOX89'"><xsl:text>O2OXXOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXXOX89'"><xsl:text>OXOXXOX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXXOXX9'"><xsl:text>OOOXXOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXXOX8X'"><xsl:text>OOOXXOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXO7X9'"><xsl:text>OO3XXO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXXO7X9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXOXX9'"><xsl:text>OOOXXOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXO7XX'"><xsl:text>OOOXXO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXO78X'"><xsl:text>OO3XXO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXXO78X'"><xsl:text>OOXXXOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXOX8X'"><xsl:text>OOOXXOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXO7XX'"><xsl:text>OOOXXO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23X5X789'"><xsl:text>O23XOX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XOX789'"><xsl:text>OX3XOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOX789'"><xsl:text>O2XXOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOXX89'"><xsl:text>O23XOXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOX7X9'"><xsl:text>O23XOX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOX78X'"><xsl:text>O2OXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOXX8X'"><xsl:text>OOOXOXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOX7XX'"><xsl:text>OOOXOX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23X56X89'"><xsl:text>OO3X56X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXX56X89'"><xsl:text>OOXXO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXOXX89'"><xsl:text>OOXXOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXO6XX9'"><xsl:text>OOXXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXO6X8X'"><xsl:text>OOXXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XX6X89'"><xsl:text>OOOXX6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3X5XX89'"><xsl:text>OOOX5XX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3X56XX9'"><xsl:text>OOOX56XX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3X56X8X'"><xsl:text>OOOX56X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23X567X9'"><xsl:text>O2OX567X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOX567X9'"><xsl:text>OXOXO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX7X9'"><xsl:text>OXOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6XX9'"><xsl:text>OXOXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXX67X9'"><xsl:text>OOOXX67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX5X7X9'"><xsl:text>OOOX5X7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX56XX9'"><xsl:text>OOOX56XX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX567XX'"><xsl:text>OOOX567XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23X5678X'"><xsl:text>O2OX5678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOX5678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXX678X'"><xsl:text>OOOXX678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX5X78X'"><xsl:text>OOOX5X78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX56X8X'"><xsl:text>OOOX56X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX567XX'"><xsl:text>OOOX567XX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234X6789'"><xsl:text>O234X6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X6789'"><xsl:text>OX34X67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4X67O9'"><xsl:text>OXX4X6OO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXX6OO9'"><xsl:text>OXXXX6OOO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4XXOO9'"><xsl:text>OXXOXXOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4X6OOX'"><xsl:text>OXXOX6OOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XX67O9'"><xsl:text>OX3XXO7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXO7O9'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXOXO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO7OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34XX7O9'"><xsl:text>OX3OXX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOXX7O9'"><xsl:text>OXXOXXOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OXXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OXX7OX'"><xsl:text>OX3OXXOOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X6XO9'"><xsl:text>OXO4X6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX6XO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34X67OX'"><xsl:text>OXO4X67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX67OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XX7OX'"><xsl:text>OXOOXX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4X6789'"><xsl:text>O2X4X6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4X6O89'"><xsl:text>OXXOX6O89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXX6O89'"><xsl:text>O2XXXOO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXOO89'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOOX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOO8X'"><xsl:text>OOXXXOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4XXO89'"><xsl:text>O2XOXXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4X6OX9'"><xsl:text>O2XOX6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4X6O8X'"><xsl:text>O2XOX6O8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XX6789'"><xsl:text>O23XXO789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO789'"><xsl:text>OX3XXO7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXO7O9'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXOXO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XXO7OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXO789'"><xsl:text>O2XXXOO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXXOO89'"><xsl:text>OXXXXOOO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOOX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXXOO8X'"><xsl:text>OOXXXOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXOX89'"><xsl:text>O2OXXOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXXOX89'"><xsl:text>OXOXXOX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXXOXX9'"><xsl:text>OOOXXOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXXOX8X'"><xsl:text>OOOXXOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXO7X9'"><xsl:text>OO3XXO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXXO7X9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXOXX9'"><xsl:text>OOOXXOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXO7XX'"><xsl:text>OOOXXO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XXO78X'"><xsl:text>OO3XXO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXXO78X'"><xsl:text>OOXXXOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXOX8X'"><xsl:text>OOOXXOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XXO7XX'"><xsl:text>OOOXXO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234XX789'"><xsl:text>O23OXX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OXX789'"><xsl:text>OX3OXXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XOXX789'"><xsl:text>O2XOXXO89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23OXXX89'"><xsl:text>O2OOXXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOOXXX89'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXXXX9'"><xsl:text>OOOOXXXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXXX8X'"><xsl:text>OOOOXXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23OXX7X9'"><xsl:text>O23OXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23OXX78X'"><xsl:text>O23OXXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234X6X89'"><xsl:text>O2O4X6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6X89'"><xsl:text>OXO4X6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX6XO9'"><xsl:text>OXOXXOXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXX6X89'"><xsl:text>OOOXX6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4XXX89'"><xsl:text>OOO4XXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4X6XX9'"><xsl:text>OOO4X6XX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4X6X8X'"><xsl:text>OOO4X6X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234X67X9'"><xsl:text>OO34X67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X67X9'"><xsl:text>OOX4X6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXX6OX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4XXOX9'"><xsl:text>OOXOXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X6OXX'"><xsl:text>OOXOX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XX67X9'"><xsl:text>OOOXX67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34XX7X9'"><xsl:text>OOO4XX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34X6XX9'"><xsl:text>OOO4X6XX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34X67XX'"><xsl:text>OOO4X67XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234X678X'"><xsl:text>O2O4X678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X678X'"><xsl:text>OXO4X67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXX67OX'"><xsl:text>OXOXXO7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XX7OX'"><xsl:text>OXOOXX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4X6XOX'"><xsl:text>OXOOX6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXX678X'"><xsl:text>OOOXX678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4XX78X'"><xsl:text>OOO4XX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4X6X8X'"><xsl:text>OOO4X6X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4X67XX'"><xsl:text>OOO4X67XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12345X789'"><xsl:text>12O45X789</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2O45X789'"><xsl:text>X2OO5X789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOO5X789'"><xsl:text>XXOOOX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOXX89'"><xsl:text>XXOOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX7X9'"><xsl:text>XXOOOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX78X'"><xsl:text>XXOOOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXX789'"><xsl:text>X2OOXX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOXX78O'"><xsl:text>XXOOXX7OO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXXX8O'"><xsl:text>XOOOXXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXX7XO'"><xsl:text>XOOOXX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OO5XX89'"><xsl:text>X2OOOXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOXX89'"><xsl:text>XXOOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOXXX9'"><xsl:text>X2OOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOXX8X'"><xsl:text>X2OOOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OO5X7X9'"><xsl:text>X2OOOX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX7X9'"><xsl:text>XXOOOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOXXX9'"><xsl:text>X2OOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOX7XX'"><xsl:text>X2OOOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OO5X78X'"><xsl:text>X2OOOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX78X'"><xsl:text>XXOOOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOXX8X'"><xsl:text>X2OOOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOOX7XX'"><xsl:text>X2OOOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XO45X789'"><xsl:text>1XOO5X789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOO5X789'"><xsl:text>XXOOOX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOXX89'"><xsl:text>XXOOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX7X9'"><xsl:text>XXOOOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX78X'"><xsl:text>XXOOOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXX789'"><xsl:text>1XOOXX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOXX7O9'"><xsl:text>XXOOXX7OO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXX7OX'"><xsl:text>OXOOXX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOO5XX89'"><xsl:text>1XOOOXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOXX89'"><xsl:text>XXOOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOOXXX9'"><xsl:text>1XOOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOOXX8X'"><xsl:text>1XOOOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOO5X7X9'"><xsl:text>1XOOOX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOOX7X9'"><xsl:text>XXOOOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOOXXX9'"><xsl:text>1XOOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOOX7XX'"><xsl:text>1XOOOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOO5X78X'"><xsl:text>1XOO5XO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOO5XO8X'"><xsl:text>XXOOOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXXO8X'"><xsl:text>OXOOXXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOO5XOXX'"><xsl:text>OXOO5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12OX5X789'"><xsl:text>12OXOX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OXOX789'"><xsl:text>X2OXOXO89</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOXOX789'"><xsl:text>1XOXOXO89</xsl:text></xsl:when>
            <xsl:when test="$board = '12OXOXX89'"><xsl:text>O2OXOXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOXX89'"><xsl:text>OXOXOXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOXXX9'"><xsl:text>OOOXOXXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOXX8X'"><xsl:text>OOOXOXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12OXOX7X9'"><xsl:text>12OXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '12OXOX78X'"><xsl:text>12OXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12O4XX789'"><xsl:text>12OOXX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXX789'"><xsl:text>X2OOXX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOXX78O'"><xsl:text>XXOOXX7OO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXXX8O'"><xsl:text>XOOOXXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2OOXX7XO'"><xsl:text>XOOOXX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXX789'"><xsl:text>1XOOXX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XXOOXX7O9'"><xsl:text>XXOOXX7OO</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXXXO9'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1XOOXX7OX'"><xsl:text>OXOOXX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = '12OOXXX89'"><xsl:text>O2OOXXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOOXXX89'"><xsl:text>OXOOXXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXXXX9'"><xsl:text>OOOOXXXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXXX8X'"><xsl:text>OOOOXXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12OOXX7X9'"><xsl:text>1OOOXX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOOOXX7X9'"><xsl:text>XOOOXX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOOXXXX9'"><xsl:text>OOOOXXXX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOOXX7XX'"><xsl:text>OOOOXX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12OOXX78X'"><xsl:text>O2OOXX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOOXX78X'"><xsl:text>OXOOXXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXXX8X'"><xsl:text>OOOOXXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OOXX7XX'"><xsl:text>OOOOXX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12O45XX89'"><xsl:text>O2O45XX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO45XX89'"><xsl:text>OXO4OXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOXX89'"><xsl:text>OXOXOXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXXX9'"><xsl:text>OXO4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXX8X'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX5XX89'"><xsl:text>OOOX5XX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4XXX89'"><xsl:text>OOO4XXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45XXX9'"><xsl:text>OOO45XXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45XX8X'"><xsl:text>OOO45XX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12O45X7X9'"><xsl:text>O2O45X7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO45X7X9'"><xsl:text>OXO4OX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX7X9'"><xsl:text>OXOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXXX9'"><xsl:text>OXO4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OX7XX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX5X7X9'"><xsl:text>OOOX5X7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4XX7X9'"><xsl:text>OOO4XX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45XXX9'"><xsl:text>OOO45XXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45X7XX'"><xsl:text>OOO45X7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12O45X78X'"><xsl:text>O2O45X78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO45X78X'"><xsl:text>OXO45XO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOX5XO8X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4XXO8X'"><xsl:text>OXOOXXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO45XOXX'"><xsl:text>OXOO5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OX5X78X'"><xsl:text>OOOX5X78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4XX78X'"><xsl:text>OOO4XX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45XX8X'"><xsl:text>OOO45XX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O45X7XX'"><xsl:text>OOO45X7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '123456X89'"><xsl:text>1234O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6X89'"><xsl:text>X23OO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX3OO6X89'"><xsl:text>XX3OOOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOO6X89'"><xsl:text>X2XOOOX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OOXX89'"><xsl:text>XO3OOXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOOXX89'"><xsl:text>XOXOOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OOXXX9'"><xsl:text>XO3OOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OOXX8X'"><xsl:text>XO3OOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO6XX9'"><xsl:text>X23OOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OO6X8X'"><xsl:text>X23OOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6X89'"><xsl:text>OX34O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6X89'"><xsl:text>OXX4O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6X89'"><xsl:text>OX3XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXX89'"><xsl:text>OX34OXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6XX9'"><xsl:text>OX34O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X8X'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6X89'"><xsl:text>1OX4O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6X89'"><xsl:text>XOX4O6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6X89'"><xsl:text>1OXXO6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXX89'"><xsl:text>1OX4OXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4O6XX9'"><xsl:text>1OX4O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6XXO'"><xsl:text>XOXOO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6XXO'"><xsl:text>OOXXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXXXO'"><xsl:text>OOX4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4O6X8X'"><xsl:text>1OX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6X89'"><xsl:text>O23XO6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6X89'"><xsl:text>OX3XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6X89'"><xsl:text>O2XXO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOXX89'"><xsl:text>O23XOXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6XX9'"><xsl:text>O23XO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6X8X'"><xsl:text>O23XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6XOX'"><xsl:text>OOXXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOXXOX'"><xsl:text>OO3XOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OXX89'"><xsl:text>1O34OXX89</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXX89'"><xsl:text>XO34OXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXX89'"><xsl:text>1OX4OXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XOXX89'"><xsl:text>1O3XOXXO9</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34OXXX9'"><xsl:text>1O34OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXXXO'"><xsl:text>XO3OOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXXXO'"><xsl:text>OOX4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XOXXXO'"><xsl:text>OO3XOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34OXX8X'"><xsl:text>1O34OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O6XX9'"><xsl:text>1234O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6XXO'"><xsl:text>X23OO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XX3OO6XXO'"><xsl:text>XX3OOOXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2XOO6XXO'"><xsl:text>X2XOOOXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'X23OOXXXO'"><xsl:text>XO3OOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6XXO'"><xsl:text>OX34O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6XXO'"><xsl:text>O2X4O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6XXO'"><xsl:text>O23XO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OXXXO'"><xsl:text>O234OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O6X8X'"><xsl:text>1234O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6XOX'"><xsl:text>XO34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6XOX'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6XOX'"><xsl:text>1OX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6XOX'"><xsl:text>1O3XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OXXOX'"><xsl:text>1O34OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234567X9'"><xsl:text>1O34567X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34567X9'"><xsl:text>XO3456OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX456OX9'"><xsl:text>XOX4O6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXOX9'"><xsl:text>XOX4OXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3X56OX9'"><xsl:text>XO3XO6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34X6OX9'"><xsl:text>XO34X6OXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4X6OXO'"><xsl:text>XOXOX6OXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XX6OXO'"><xsl:text>XO3XXOOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34XXOXO'"><xsl:text>XO3OXXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO345XOX9'"><xsl:text>XO34OXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXOX9'"><xsl:text>XOX4OXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3456OXX'"><xsl:text>XO34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4567X9'"><xsl:text>1OX456OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX456OX9'"><xsl:text>XOX4O6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXOX9'"><xsl:text>XOX4OXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX56OX9'"><xsl:text>1OXXO6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXOXOX9'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6OXX'"><xsl:text>1OXXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4X6OX9'"><xsl:text>OOX4X6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXX6OX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4XXOX9'"><xsl:text>OOXOXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X6OXX'"><xsl:text>OOXOX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX45XOX9'"><xsl:text>1OX45XOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX45XOXO'"><xsl:text>XOXO5XOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX5XOXO'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4XXOXO'"><xsl:text>1OXOXXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX456OXX'"><xsl:text>1OX45OOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX45OOXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX5OOXX'"><xsl:text>OOXX5OOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4XOOXX'"><xsl:text>OOX4XOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X567X9'"><xsl:text>1O3X56OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3X56OX9'"><xsl:text>XO3XO6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX56OX9'"><xsl:text>1OXXO6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXXO6OX9'"><xsl:text>XOXXOOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXOXOX9'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6OXX'"><xsl:text>1OXXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XX6OX9'"><xsl:text>1O3XXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XXOOX9'"><xsl:text>XO3XXOOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXXOOX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XXOOXX'"><xsl:text>OO3XXOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X5XOX9'"><xsl:text>1O3XOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXOXOX9'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XOXOXX'"><xsl:text>1OOXOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X56OXX'"><xsl:text>1OOX56OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOOX56OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOXX6OXX'"><xsl:text>OOOXX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOX5XOXX'"><xsl:text>OOOX5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34X67X9'"><xsl:text>OO34X67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X67X9'"><xsl:text>OOX4X6OX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXX6OX9'"><xsl:text>OOXXXOOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4XXOX9'"><xsl:text>OOXOXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X6OXX'"><xsl:text>OOXOX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XX67X9'"><xsl:text>OOOXX67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34XX7X9'"><xsl:text>OOO4XX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34X6XX9'"><xsl:text>OOO4X6XX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34X67XX'"><xsl:text>OOO4X67XX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O345X7X9'"><xsl:text>1O345XOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO345XOX9'"><xsl:text>XO34OXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4OXOX9'"><xsl:text>XOX4OXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX45XOX9'"><xsl:text>1OX45XOXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX45XOXO'"><xsl:text>XOXO5XOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX5XOXO'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4XXOXO'"><xsl:text>1OXOXXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X5XOX9'"><xsl:text>1O3XOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XOXOX9'"><xsl:text>XOOXOXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXOXOX9'"><xsl:text>1OXXOXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3XOXOXX'"><xsl:text>1OOXOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34XXOX9'"><xsl:text>1O3OXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OXXOX9'"><xsl:text>XO3OXXOXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXOXXOX9'"><xsl:text>OOXOXXOX9</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3OXXOXX'"><xsl:text>OO3OXXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O345XOXX'"><xsl:text>1OO45XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOO45XOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOX5XOXX'"><xsl:text>OOOX5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OO4XXOXX'"><xsl:text>OOO4XXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3456XX9'"><xsl:text>1O3456XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3456XXO'"><xsl:text>XO3O56XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXO56XXO'"><xsl:text>XOXOO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OX6XXO'"><xsl:text>XOOOX6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3O5XXXO'"><xsl:text>XOOO5XXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX456XXO'"><xsl:text>1OX4O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6XXO'"><xsl:text>XOXOO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXXO6XXO'"><xsl:text>OOXXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4OXXXO'"><xsl:text>OOX4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X56XXO'"><xsl:text>OO3X56XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXX56XXO'"><xsl:text>OOXXO6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XX6XXO'"><xsl:text>OOOXX6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3X5XXXO'"><xsl:text>OOOX5XXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34X6XXO'"><xsl:text>1OO4X6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOO4X6XXO'"><xsl:text>XOO4XOXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOXX6XXO'"><xsl:text>OOOXX6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1OO4XXXXO'"><xsl:text>OOO4XXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O345XXXO'"><xsl:text>OO345XXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX45XXXO'"><xsl:text>OOX4OXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3X5XXXO'"><xsl:text>OOOX5XXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34XXXXO'"><xsl:text>OOO4XXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34567XX'"><xsl:text>1O3456OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3456OXX'"><xsl:text>XO34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX456OXX'"><xsl:text>1OX45OOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX45OOXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OXX5OOXX'"><xsl:text>OOXX5OOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OX4XOOXX'"><xsl:text>OOX4XOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O3X56OXX'"><xsl:text>1OOX56OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOOX56OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOXX6OXX'"><xsl:text>OOOXX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOX5XOXX'"><xsl:text>OOOX5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O34X6OXX'"><xsl:text>OO34X6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOX4X6OXX'"><xsl:text>OOXOX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XX6OXX'"><xsl:text>OOOXX6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO34XXOXX'"><xsl:text>OOO4XXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1O345XOXX'"><xsl:text>1OO45XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOO45XOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OOX5XOXX'"><xsl:text>OOOX5XOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1OO4XXOXX'"><xsl:text>OOO4XXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12345678X'"><xsl:text>1234O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O678X'"><xsl:text>XO34O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O678X'"><xsl:text>XOX4O67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO678X'"><xsl:text>XO3XO67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OX78X'"><xsl:text>XO34OX7OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O6X8X'"><xsl:text>XO34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O67XX'"><xsl:text>XO34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6OXX'"><xsl:text>XOX4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6OXX'"><xsl:text>XOOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OXOXX'"><xsl:text>XOO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O678X'"><xsl:text>OX34O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O678X'"><xsl:text>OXX4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OOX8X'"><xsl:text>OXXOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OO7XX'"><xsl:text>OXXOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OX78X'"><xsl:text>OXO4OX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXX8X'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OX7XX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X8X'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O67XX'"><xsl:text>OX34O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6OXX'"><xsl:text>OXXOO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6OXX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXOXX'"><xsl:text>OXO4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O678X'"><xsl:text>12X4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4OO78X'"><xsl:text>X2XOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XX4OO78X'"><xsl:text>1XXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = '12XXOO78X'"><xsl:text>O2XXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOOX8X'"><xsl:text>O2XXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO7XX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OOX8X'"><xsl:text>12XOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4OO7XX'"><xsl:text>12XOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO678X'"><xsl:text>O23XO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO678X'"><xsl:text>OXOXO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6X8X'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO67XX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO678X'"><xsl:text>O2XXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXXOO78X'"><xsl:text>OXXXOOO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOOX8X'"><xsl:text>O2XXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO7XX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOX78X'"><xsl:text>O2OXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXOX78X'"><xsl:text>OXOXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOXX8X'"><xsl:text>OOOXOXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOX7XX'"><xsl:text>OOOXOX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6X8X'"><xsl:text>O23XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6XOX'"><xsl:text>OOXXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOXXOX'"><xsl:text>OO3XOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO67XX'"><xsl:text>O23XO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6OXX'"><xsl:text>OXOXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6OXX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOXOXX'"><xsl:text>O2OXOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OX78X'"><xsl:text>12O4OX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2O4OX78X'"><xsl:text>X2O4OXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '1XO4OX78X'"><xsl:text>1XO4OXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12OXOX78X'"><xsl:text>12OXOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = '12O4OXX8X'"><xsl:text>12O4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2O4OXXOX'"><xsl:text>XOO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XO4OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12OXOXXOX'"><xsl:text>1OOXOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12O4OX7XX'"><xsl:text>12O4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O6X8X'"><xsl:text>1234O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6XOX'"><xsl:text>XO34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6XOX'"><xsl:text>OX34O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6XOX'"><xsl:text>OXX4OOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6XOX'"><xsl:text>OXOXO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OXXOX'"><xsl:text>OXO4OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6XOX'"><xsl:text>1OX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6XOX'"><xsl:text>1O3XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OXXOX'"><xsl:text>1O34OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O67XX'"><xsl:text>1234O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6OXX'"><xsl:text>X2O4O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6OXX'"><xsl:text>1XO4O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6OXX'"><xsl:text>12X4OOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X2X4OOOXX'"><xsl:text>X2XOOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1XX4OOOXX'"><xsl:text>1XXOOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '12XXOOOXX'"><xsl:text>O2XXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6OXX'"><xsl:text>12OXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OXOXX'"><xsl:text>12O4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'X234O6789'"><xsl:text>XO34O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOX4O6789'"><xsl:text>XOX4O67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3XO6789'"><xsl:text>XO3XO67O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34OX789'"><xsl:text>XO34OX7O9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O6X89'"><xsl:text>XO34O6XO9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O67X9'"><xsl:text>XO3OO67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOXOO67X9'"><xsl:text>XOXOOO7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OOX7X9'"><xsl:text>XOOOOX7X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOOOOXXX9'"><xsl:text>XOOOOXXXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'XOOOOX7XX'"><xsl:text>XOOOOXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OO6XX9'"><xsl:text>XO3OOOXX9</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO3OO67XX'"><xsl:text>XO3OOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'XO34O678X'"><xsl:text>XO34O67OX</xsl:text></xsl:when>
            <xsl:when test="$board = '1X34O6789'"><xsl:text>OX34O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6789'"><xsl:text>OXX4O678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6789'"><xsl:text>OX3XO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OX789'"><xsl:text>OX34OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X89'"><xsl:text>OX34O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O67X9'"><xsl:text>OX34O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O678X'"><xsl:text>OX3OO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOO678X'"><xsl:text>OXXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OOX78X'"><xsl:text>OX3OOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OO6X8X'"><xsl:text>OX3OOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OO67XX'"><xsl:text>OX3OOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '12X4O6789'"><xsl:text>O2X4O6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4O6789'"><xsl:text>OXX4O678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6789'"><xsl:text>O2XXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OX789'"><xsl:text>O2X4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6X89'"><xsl:text>O2X4O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O67X9'"><xsl:text>O2X4O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O678X'"><xsl:text>O2X4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OO78X'"><xsl:text>OXXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO78X'"><xsl:text>OOXXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXOOX8X'"><xsl:text>OOXXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXOO7XX'"><xsl:text>OOXXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OOX8X'"><xsl:text>O2XOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OO7XX'"><xsl:text>O2XOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '123XO6789'"><xsl:text>O23XO6789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3XO6789'"><xsl:text>OX3XO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXO6789'"><xsl:text>O2XXO678O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOX789'"><xsl:text>O23XOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6X89'"><xsl:text>O23XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO67X9'"><xsl:text>O23XO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO678X'"><xsl:text>OO3XO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXO678X'"><xsl:text>OOXXO67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XOX78X'"><xsl:text>OOOXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XO6X8X'"><xsl:text>OOOXO6X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XO67XX'"><xsl:text>OOOXO67XX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234OX789'"><xsl:text>O234OX789</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34OX789'"><xsl:text>OX34OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OX789'"><xsl:text>O2X4OX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XOX789'"><xsl:text>O23XOX78O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXX89'"><xsl:text>O234OXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OX7X9'"><xsl:text>O234OX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OX78X'"><xsl:text>O2O4OX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OX78X'"><xsl:text>OXO4OXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOX78X'"><xsl:text>OOOXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4OXX8X'"><xsl:text>OOO4OXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4OX7XX'"><xsl:text>OOO4OX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O6X89'"><xsl:text>O234O6X89</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6X89'"><xsl:text>OX34O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6X89'"><xsl:text>O2X4O6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6X89'"><xsl:text>O23XO6X8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXX89'"><xsl:text>O234OXX8O</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O6XX9'"><xsl:text>O234O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O6X8X'"><xsl:text>O234O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6XOX'"><xsl:text>OXO4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6XOX'"><xsl:text>OXOXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXXOX'"><xsl:text>OXOOOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6XOX'"><xsl:text>OOX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6XOX'"><xsl:text>OO3XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXXOX'"><xsl:text>OO34OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O67X9'"><xsl:text>O234O67X9</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O67X9'"><xsl:text>OX34O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O67X9'"><xsl:text>O2X4O67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO67X9'"><xsl:text>O23XO67XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OX7X9'"><xsl:text>O234OX7XO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O6XX9'"><xsl:text>O234O6XXO</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O67XX'"><xsl:text>O234O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6OXX'"><xsl:text>OXO4O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6OXX'"><xsl:text>O2XOO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6OXX'"><xsl:text>O2OXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXOXX'"><xsl:text>O2O4OXOXX</xsl:text></xsl:when>
            <xsl:when test="$board = '1234O678X'"><xsl:text>O234O678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O678X'"><xsl:text>OX3OO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXXOO678X'"><xsl:text>OXXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OOX78X'"><xsl:text>OX3OOXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OO6X8X'"><xsl:text>OX3OOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX3OO67XX'"><xsl:text>OX3OOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O678X'"><xsl:text>O2X4OO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXX4OO78X'"><xsl:text>OXXOOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2XXOO78X'"><xsl:text>OOXXOO78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXOOX8X'"><xsl:text>OOXXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXOO7XX'"><xsl:text>OOXXOOOXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OOX8X'"><xsl:text>O2XOOOX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4OO7XX'"><xsl:text>O2XOOO7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO678X'"><xsl:text>OO3XO678X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OOXXO678X'"><xsl:text>OOXXO67OX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XOX78X'"><xsl:text>OOOXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XO6X8X'"><xsl:text>OOOXO6X8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OO3XO67XX'"><xsl:text>OOOXO67XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OX78X'"><xsl:text>O2O4OX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OX78X'"><xsl:text>OXO4OXO8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2OXOX78X'"><xsl:text>OOOXOX78X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4OXX8X'"><xsl:text>OOO4OXX8X</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2O4OX7XX'"><xsl:text>OOO4OX7XX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O6X8X'"><xsl:text>O234O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6XOX'"><xsl:text>OXO4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXOXO6XOX'"><xsl:text>OXOXOOXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OXO4OXXOX'"><xsl:text>OXOOOXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6XOX'"><xsl:text>OOX4O6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6XOX'"><xsl:text>OO3XO6XOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXXOX'"><xsl:text>OO34OXXOX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234O67XX'"><xsl:text>O234O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'OX34O6OXX'"><xsl:text>OXO4O6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O2X4O6OXX'"><xsl:text>O2XOO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O23XO6OXX'"><xsl:text>O2OXO6OXX</xsl:text></xsl:when>
            <xsl:when test="$board = 'O234OXOXX'"><xsl:text>O2O4OXOXX</xsl:text></xsl:when>
            <xsl:otherwise><xsl:text>error</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
