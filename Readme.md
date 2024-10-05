<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/kulvind3r/gaminggaiden)](https://github.com/kulvind3r/gaminggaiden/stargazers)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fkulvind3r%2FGamingGaiden&count_bg=%23EF476F&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=Visitors&edge_flat=false)](https://hits.seeyoufarm.com)
[![GitHub Downloads (latest)](https://img.shields.io/github/downloads/kulvind3r/gaminggaiden/latest/total?label=Downloads%20-%20Latest&color=%23FFD166)](https://github.com/kulvind3r/GamingGaiden/releases/latest)
![GitHub Downloads (all)](https://img.shields.io/github/downloads/kulvind3r/gaminggaiden/total?label=Downloads%20-%20Total&color=%23FFD166)

[![Codacy Quality](https://app.codacy.com/project/badge/Grade/c4a01f22c3864d8c80b8c6891a6feb5f)](https://app.codacy.com/gh/kulvind3r/GamingGaiden/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/kulvind3r/gaminggaiden?label=Commit%20Activity&color=%23073B4C)](https://github.com/kulvind3r/gaminggaiden/graphs/commit-activity)
[![GitHub issues](https://img.shields.io/github/issues/kulvind3r/gaminggaiden?label=Issues&color=%23118AB2)](https://github.com/kulvind3r/gaminggaiden/issues)

![Gaming Gaiden](./readme-files/GamingGaidenBanner.png)

</div>

### 外伝 (Gaiden)

Japanese

noun (common)

A Tale; Side Story;

A small powershell tray application for windows os to track gaming time. Helps you record your gaming story over the years.

![demo_multiview](https://github.com/user-attachments/assets/b07520a0-f9c6-4e68-9356-ff5cc0b4cfbc)

## Features
- #### Time Tracking and Emulator Support
    - Tracks play time for PC or emulated games.
    - Auto tracks new roms after registering any emulator just once.
    - Supports Retroarch cores.
    - Detects and removes idle time from gaming sessions.
    - Out of box HWiNFO64 integration with session time and tracking status metrics.
- #### UI and Statistics
    - Fast browser based UI with search and sorting. Quick view popup for recent games.
    - Multiple in depth statistics on gaming. Lifetime summary, monthly/yearly time analysis, most played games, games per emulator etc.
    - Integrated google image search for game icons / box art.
    - Mark games as Finished / Playing to track backlog completion.
- #### Quality of Life Features
    - Small size (~7 MB). High performance (Sub 5 sec game detection). Light on cpu & ram.
    - Completely offline and portable, all data stored in local database.
    - Automated data backup after each gaming session.

### [Video Demo](https://github.com/user-attachments/assets/cf4cdc10-1c6a-4b63-92d5-3eddd675d1ae)

## How to install / upgrade / use
1. Open a Powershell window as admin and run below command to allow powershell modules to load on your system. Choose `Yes` when prompted.
    - `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

2. Download ***GamingGaiden.zip*** from the [latest release](https://github.com/kulvind3r/GamingGaiden/releases/latest).
3. Extract ***GamingGaiden*** folder and Run `Install.bat`. Choose Yes/No for autostart at Boot.
4. Use the shortcut on desktop / start menu for launching the application.
5. Regularly backup your `GamingGaiden.db` and `backups` folder to avoid data loss. Click ***Settings => Open Install Directory*** option in app menu to find them.

## Unknown Publisher
Windows smart screen may give a warning that application is from ***Unknown Publisher*** due to lack of signature by a public CA approved certificate.
These certifactes cost hundreds of dollars per year. Can't afford them.

## Antivirus False Positives
Powershell Module [ps12exe](https://github.com/steve02081504/ps12exe) written by [Steve Green](https://github.com/steve02081504) is used to convert the primary script of Gaming Gaiden into native exe.

Some antivirus solutions give false positives for such autogenerated executables. Check the ***Virus Total Scan Link*** for each release and make your own decision. 

Open Source softwares do not come with any warranty. Users are responsible for their own actions & saftey.

## Attributions
Made with love using 

- [PSSQLite](https://www.powershellgallery.com/packages/PSSQLite) by [Warren Frame](https://github.com/RamblingCookieMonster)
- [ps12exe](https://github.com/steve02081504/ps12exe) by [Steve Green](https://github.com/steve02081504)
- [DataTables](https://datatables.net/)
- [Jquery](https://jquery.com/)
- [ChartJs](https://www.chartjs.org/)
- Various Icons from [Icons8](https://icons8.com)
- Game Cartridge Icon from [FreePik on Flaticon](https://www.flaticon.com/free-icons/game-cartridge)
- Cute [Ninja Vector by Catalyststuff on Freepik](https://www.freepik.com/free-vector/cute-ninja-gaming-cartoon-vector-icon-illustration-people-technology-icon-concept-isolated-flat_42903434.htm)
- [Ninja Garden Font](https://www.fontspace.com/ninja-garden-font-f32923) by [Iconian Fonts](https://www.fontspace.com/iconian-fonts)
