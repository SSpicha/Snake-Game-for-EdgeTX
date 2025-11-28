# 🐍 Snake Game for EdgeTX

A classic Snake game script written in Lua, designed for **EdgeTX** radios with color screens (tested on **RadioMaster TX15 and TX16S**).

![Lua](https://img.shields.io/badge/Lua-EdgeTX-blue) ![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

* **Adaptive Resolution:** Automatically scales to the screen grid (optimized for 480x272).
* **Progressive Difficulty:** The game starts slow and gets faster every 10 points.
* **High Score System:** Saves your best score in RAM (resets when you exit the script).
* **Haptic & Sound Feedback:**
    * Beeps when eating food.
    * "Level Up" sound when speed increases.
    * Vibration (Haptic) and crash sound on Game Over.
* **Safety Delay:** 1-second delay after crashing to prevent accidental restarts.

## 🎮 Controls

| Input | Action |
| :--- | :--- |
| **Right Stick** (Aileron/Elevator) | Control the Snake (Up, Down, Left, Right) |
| **Stick Move** (after crash) | Restart Game |
| **RTN / BACK** | Exit Game |

## 📥 Installation

1.  Download the `Snake.lua` file.
2.  Connect your radio to the PC via USB (Storage Mode).
3.  Copy `Snake.lua` to the SD Card folder:  
    `/SCRIPTS/TOOLS/`
4.  Eject the radio.
5.  On the radio, press **SYS**, go to the **TOOLS** page, and run **Snake**.

## 🛠Configuration

You can adjust the game settings at the top of the `Snake.lua` file:

```lua
local cellSize = 10      -- Size of the snake/food blocks
local startSpeed = 20    -- Initial speed (higher = slower)
local speedStep = 2      -- How much speed increases per level
local restartDelay = 100 -- Delay before restart is allowed (100 = 1 sec)

