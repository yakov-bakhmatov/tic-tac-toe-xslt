<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" encoding="utf-8"/>
    <xsl:template match="/">
        <xsl:variable name="board" select="/game/board"/>
        <div>
            <svg width="150" height="150" viewBox="0 0 150 150" xmlns="http://www.w3.org/2000/svg">
                <line x1="0" x2="150" y1="50" y2="50" stroke="black" stroke-width="2"/>
                <line x1="0" x2="150" y1="100" y2="100" stroke="black" stroke-width="2"/>
                <line x1="50" x2="50" y1="0" y2="150" stroke="black" stroke-width="2"/>
                <line x1="100" x2="100" y1="0" y2="150" stroke="black" stroke-width="2"/>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 1, 1)"/>
                    <xsl:with-param name="position" select="'25, 25'"/>
                    <xsl:with-param name="index" select="1"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 2, 1)"/>
                    <xsl:with-param name="position" select="'75, 25'"/>
                    <xsl:with-param name="index" select="2"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 3, 1)"/>
                    <xsl:with-param name="position" select="'125, 25'"/>
                    <xsl:with-param name="index" select="3"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 4, 1)"/>
                    <xsl:with-param name="position" select="'25, 75'"/>
                    <xsl:with-param name="index" select="4"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 5, 1)"/>
                    <xsl:with-param name="position" select="'75, 75'"/>
                    <xsl:with-param name="index" select="5"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 6, 1)"/>
                    <xsl:with-param name="position" select="'125, 75'"/>
                    <xsl:with-param name="index" select="6"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 7, 1)"/>
                    <xsl:with-param name="position" select="'25, 125'"/>
                    <xsl:with-param name="index" select="7"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 8, 1)"/>
                    <xsl:with-param name="position" select="'75, 125'"/>
                    <xsl:with-param name="index" select="8"/>
                </xsl:call-template>
                <xsl:call-template name="cell">
                    <xsl:with-param name="value" select="substring($board, 9, 1)"/>
                    <xsl:with-param name="position" select="'125, 125'"/>
                    <xsl:with-param name="index" select="9"/>
                </xsl:call-template>
            </svg>
            <div class="spacer"/>
            <div>
                <xsl:choose>
                    <xsl:when test="/game/state = 'X'">
                        <xsl:text>Ты победил. Давай ещё раз.</xsl:text>
                    </xsl:when>
                    <xsl:when test="/game/state = 'O'">
                        <xsl:text>Я победил. Давай ещё раз.</xsl:text>
                    </xsl:when>
                    <xsl:when test="/game/state = 'tie'">
                        <xsl:text>Ничья. Давай ещё раз.</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </div>
            <div>
                <xsl:value-of select="/game/message"/>
            </div>
            <div>
                <xsl:text>Твой ход (r - начнём с начала)</xsl:text>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="cell">
        <xsl:param name="value"/>
        <xsl:param name="position"/>
        <xsl:param name="index"/>
        <g transform="translate({$position})">
            <xsl:choose>
                <xsl:when test="$value = 'X'">
                    <line x1="-20" x2="20" y1="-20" y2="20" stroke="green" stroke-width="8"/>
                    <line x1="20" x2="-20" y1="-20" y2="20" stroke="green" stroke-width="8"/>
                </xsl:when>
                <xsl:when test="$value = 'O'">
                    <circle cx="0" cy="0" r="20" stroke="blue" fill="transparent" stroke-width="8"/>
                </xsl:when>
                <xsl:otherwise>
                    <text x="0" y="0" text-anchor="middle" dominant-baseline="middle"><xsl:value-of select="$value"/></text>
                </xsl:otherwise>
            </xsl:choose>
            <rect class="btn" x="-23" y="-23" width="45" height="45" onclick="onSvgClick({$index})"/>
        </g>
    </xsl:template>

</xsl:stylesheet>
