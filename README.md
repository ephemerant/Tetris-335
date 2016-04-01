# Tetris

## Table of Contents

1. [Introduction](#introduction)
1. [Background](#background)
1. [Code](#code)
1. [Documentation](#documentation)
1. [Problems & Solutions](#problems--solutions)
1. [Future Work](#future-work)
1. [Conclusions](#conclusions)
1. [User Manual](#user-manual)

## Introduction

This project was a collaboration between [Clayton McGuire]() and [Chris Loos]() for the [Computer Structures](http://www.soic.indiana.edu/undergraduate/courses/index.html?number=c335&department=csci) class at IUS.

The general requirements were:

1. Create a game
1. The majority of it had to be programmed in Assembly

## Background

![](http://i.imgur.com/1rEzStd.png)

> In 1984, Alexey Pajitnov was diligently programming computer games that tested the capabilities of new equipment developed by the USSR. In his spare time, he drew inspiration from his favorite puzzle board game, Pentominos, and decided to create a computer game for himself. Pajitnov envisioned an electronic game that let players arrange puzzle pieces in real time as they fell from the top of the playing field. The resulting design was a game that used seven distinctive geometric playing pieces, each made up of four squares. Pajitnov called this game “Tetris,” a combination of “tetra” (the Greek word meaning “four”) and “tennis” (his favorite sport).

*--[Tetris.com](http://tetris.com/about-tetris/)*

## Code

## Documentation

## Problems & Solutions

#### Block Rotations

The general clockwise rotation of a 4x4 zero-indexed grid is a simple transformation of its coordinates (x, y) to (3-y, x).

In order to keep the pieces centered in their grids, if the first row is blank, everything is shifted up by one, unless it's the "O" piece.

These methods combine provide an algorithm that exactly imitates the following image, except for the "S" and "Z" pieces. These pieces now have 4 states instead of 2, which we may address at a later time.

*Note: Clockwise rotations go from right to left in this image*

![](https://i.imgur.com/6AMgXMy.png)

*--[ColinFahey.com](http://colinfahey.com/tetris/tetris.html)*

#### Smooth Controls

## Future Work

## Conclusions

## User Manual