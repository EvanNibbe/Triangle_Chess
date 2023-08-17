# Triangle_Chess
This describes a Godot-based video game to play chess on a chess board that is based on the hexagonal chess board seen in CGP Grey's video "Can Chess with Hexagons?" That chessboard is revised by cutting each hexagon into 6 equilateral triangles. The piece movement for all pieces is thus changed. Needs AI or Multiplayer.
The Godot folder of this repository contains a branch of Godot that I have personally edited. 
That branch (in the Godot folder) is under the MIT open source license as per the statement in the official godotengine/godot repository.
The compilation process for the contents of the godot folder is:
1. Download godot with the command line statement: "git clone https://github.com/godotengine/godot"
2. on the command line, use cd to get into the "godot" folder.
3. Download the Singletons folder in this repository.
4. Replace (while preserving path names exactly) the matching 6 files in the godot folder with the files from the singletons folder.
5. On the command line, use cd to get back to the root (real) godot folder downloaded from https://github.com/godotengine/godot
6. Follow the instructions for compiling on your platform at https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html
