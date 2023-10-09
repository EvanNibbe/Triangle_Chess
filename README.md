# Triangle_Chess
This describes a Godot-based video game to play chess on a chess board that is based on the hexagonal chess board seen in CGP Grey's video "Can Chess with Hexagons?" That chessboard is revised by cutting each hexagon into 6 equilateral triangles. The piece movement for all pieces is thus changed. Needs AI or Multiplayer.
The Godot folder of this repository contains a branch of Godot that I have personally edited. 
That branch (in the Godot folder) is under the MIT open source license as per the statement in the official godotengine/godot repository.
The compilation process for the contents of the godot folder is:
1. Download the repository with git clone.
2. on the command line, use cd to get into the "godot" folder.
3. Follow the instructions for compiling on your platform at https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html
4. cd bin
5. open the one file in the bin folder (this is the godot executable).
6. use "scan" and find the Triangle_Chess/Triangle_Chess folder, and press "choose current folder" (or the equivalent statement)


# Compiling with MacOS
cd ~                                                                                                                <br>
brew install cmake                                                                                                  <br>
brew install python3                                                                                                <br>
git clone https://github.com/KhronosGroup/MoltenVK.git                                                              <br>
cd MoltenVK                                                                                                         <br>
./fetchDependencies --macos                                                                                         <br>
make macos                                                                                                          <br>
                                                                                                                    <br>
#cd back to the godot folder, presumably "cd &#126;/TriangleChess/godot"                                                 <br>
scons target=editor CXXFLAGS=-O3 use_lto=yes platform=macos vulkan_sdk_path=&#126;/MoltenVK                              <br>
