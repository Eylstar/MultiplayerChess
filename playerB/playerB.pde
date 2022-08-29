import processing.net.*;
Client c;
String input;
int[] data;

PImage W_king, B_king, W_queen, B_queen, W_fool, B_fool, W_tower, B_tower, W_horse, B_horse, W_pawn, B_pawn;
int[][] grid;
boolean[][] boolGrid;
int rows = 8;
float spriteSize;
float caseSpace;

//----- COLORS -----//
color greenSelected = color(218,255,150);
color darkCase = color(151,76,17);
color lightCase = color(255,191,100);
color lightHover = color(254,209,145);
color darkHover = color(229,134,65);
color darkMove = color(134,196,190);
color hoverMove = color(169, 231, 225);
color lightMove = color(146,213,206);
boolean isDarkCase = false;


PVector caseHovered = new PVector();
int selectedCaseX, selectedCaseY = -1;
int previousSelectedCaseX, previousSelectedCaseY = -1;

boolean imWhitePlayer = false;
boolean myTurnToPlay = false;

void loadSprites()                   //Chargement en mémoire des sprites
{
  W_king = loadImage("W_king.png");
  B_king = loadImage("B_king.png");
  W_queen = loadImage("W_queen.png");
  B_queen = loadImage("B_queen.png");
  W_fool = loadImage("W_fool.png");
  B_fool = loadImage("B_fool.png");
  W_tower = loadImage("W_tower.png");
  B_tower = loadImage("B_tower.png");
  W_horse = loadImage("W_horse.png");
  B_horse = loadImage("B_horse.png");
  W_pawn = loadImage("W_pawn.png");
  B_pawn = loadImage("B_pawn.png");
}

void initGrids()
{
  grid = new int[][]{ {2, 3, 4, 6, 5, 4, 3, 2},
                      {1, 1, 1, 1, 1, 1, 1, 1},
                      {0,  0,  0,  0,  0,  0,  0,  0},
                      {0,  0,  0,  0,  0,  0,  0,  0},
                      {0,  0,  0,  0,  0,  0,  0,  0},
                      {0,  0,  0,  0,  0,  0,  0,  0},
                      {11,  11,  11,  11,  11,  11,  11,  11},
                      {12,  13,  14,  15,  16,  14,  13,  12}};
                     
                   
  boolGrid = new boolean[rows][rows];
}

void setup()
{ 
  size(800,800);
  caseSpace = width / rows;
  spriteSize = caseSpace / 1.2;
  c = new Client(this, "192.168.1.15", 12345);
  loadSprites();
  initGrids();
}

void draw()
{
  caseHovered.x = calculateMouseCase(true);
  caseHovered.y = calculateMouseCase(false);
  displayGrid();
  readData();
}

void readData()
{
  if (c.available() > 0) {
    input = c.readString();
    input = input.substring(0,input.indexOf("\n"));
    data = int(split(input, ' '));
    grid[(rows-data[1])-1][(rows-data[0])-1] = data[2];
    grid[(rows-data[4])-1][(rows-data[3])-1] = 0;
    myTurnToPlay = true;
  }
}

void sendData(int xD, int yD, int vD, int xI, int yI)
{
  c.write(xD + " " + yD + " " + vD + " " + xI + " " + yI + "\n");
}

void displayGrid(){
  color col;
  for(int i=0; i<rows; i++)
  {
    isDarkCase = !isDarkCase;
    for(int j=0; j<rows; j++)
    {
      isDarkCase = !isDarkCase;
      col = chooseCaseColor(i, j);
      drawCase(i,j,col);
    }
  }
}

void drawCase(int x, int y, color col)         //Drawing of the case, his shape, color, and the sprite inside
{
  noStroke();
  fill(col);
  rect(x*caseSpace, y*caseSpace, caseSpace, caseSpace);
  int value = grid[y][x];
  switch(value)
  {
    case 1: displaySprite(W_pawn, x, y); break;
    case 2: displaySprite(W_tower, x, y); break;
    case 3: displaySprite(W_horse, x, y); break;
    case 4: displaySprite(W_fool, x, y); break;
    case 5: displaySprite(W_queen, x, y); break;
    case 6: displaySprite(W_king, x, y); break;
    case 11: displaySprite(B_pawn, x, y); break;
    case 12: displaySprite(B_tower, x, y); break;
    case 13: displaySprite(B_horse, x, y); break;
    case 14: displaySprite(B_fool, x, y); break;
    case 15: displaySprite(B_queen, x, y); break;
    case 16: displaySprite(B_king, x, y); break;
  }
}

void displaySprite(PImage img, int x, int y)
{
  image(img, x*caseSpace + caseSpace/12, y*caseSpace + caseSpace/12, spriteSize, spriteSize);
}

void mousePressed()                                                                //At every press of the mouse
{
  int pressedX = calculateMouseCase(true); 
  int pressedY = calculateMouseCase(false); 
  int value = grid[pressedY][pressedX];                                            //Getting the value of the clicked case
  
  if(boolGrid[pressedY][pressedX] == true && myTurnToPlay)                                         //First checking if it's a possible movement of the previous piece
  {
    changeSelectedValues(pressedX, pressedY);
    moveToDestination();
    //imWhitePlayer = !imWhitePlayer;
    myTurnToPlay = false;
  }
  else if(value != 0 && isThisCaseColor(pressedX, pressedY, imWhitePlayer) && myTurnToPlay)       //Then checking if this case is occupied and if it's your color
  {
    changeSelectedValues(pressedX, pressedY);
    resetBoolGrid();
    initiateMove(computeDestinations(selectedCaseX, selectedCaseY, false));       //If it's ok, I compute every destination possible for this case and sent the list to Initiate move
  }
  else if(value == 0 || isThisCaseColor(pressedX, pressedY, !imWhitePlayer) && myTurnToPlay)      //Then if the pressed case make non sense, unselect the case
  {
    changeSelectedValues(-1,-1);
    resetBoolGrid();
  }
}

void changeSelectedValues(int x, int y)                 //Switch variables value for the new selected case
{
  previousSelectedCaseX = selectedCaseX;                //The selected case become the previous one and the pressed one the selected
  previousSelectedCaseY = selectedCaseY;
  selectedCaseX = x;
  selectedCaseY = y;
}

void moveToDestination()            //Simply move the selected piece to the pressed location
{
  grid[selectedCaseY][selectedCaseX] = grid[previousSelectedCaseY][previousSelectedCaseX];        //Update value of the case
  sendData(selectedCaseX, selectedCaseY, grid[previousSelectedCaseY][previousSelectedCaseX], previousSelectedCaseX, previousSelectedCaseY);
  grid[previousSelectedCaseY][previousSelectedCaseX] = 0;      //Set free his previous location

  selectedCaseX = -1;
  selectedCaseY = -1;
  resetBoolGrid();
}

ArrayList computeDestinations(int x, int y, boolean danger)                            //For any piece, create a list for every destination possible
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  int value = grid[y][x];
  if(value > 10) value -= 10;                                         //No matter the color, the calculation will be the same
  switch(value)
  {
    case 1: destinations.addAll(calcPawnMovement(x, y, danger)); break;
    case 2: destinations.addAll(calcTowerMovement(x, y)); break;
    case 3: destinations.addAll(calcHorseMovement(x, y)); break;
    case 4: destinations.addAll(calcFoolMovement(x, y)); break;
    case 5: destinations.addAll(calcTowerMovement(x, y)); destinations.addAll(calcFoolMovement(x, y)); break;
    case 6: destinations.addAll(calcKingMovement(x, y)); break;
  }
  return destinations;
}

void initiateMove(ArrayList<PVector> destList)            //Void to calculate if the player is in check or not, and then calculate what destinations are valid or not
{
  for(int i = 0; i < destList.size(); i++)                //For each of the destinations possible of my case
  {
    int[][] tempGrid = new int[rows][];                   //Create a new grid to store the value of my board
  
    for(int j=0; j<rows; j++)                             //Put the value of the initial grid in the storage grid
    {
      tempGrid[j] = new int[rows];
      arrayCopy(grid[j], tempGrid[j]);
    }
    
    int boolY = int(destList.get(i).x);
    int boolX = int(destList.get(i).y);
    grid[boolY][boolX] = grid[selectedCaseY][selectedCaseX];
    grid[selectedCaseY][selectedCaseX] = 0;                           //Simulate a piece movement (for each destination possible)
    
    ArrayList<PVector> allSimulatedDest = new ArrayList<PVector>();   //Create a new list of destinations, to calculate each possible movement of the other player at the next move
    for(int j=0; j<rows; j++)
    {
      for(int k=0; k<rows; k++)
      {
        if(grid[k][j] >= 11 && grid[k][j] <= 16 && imWhitePlayer)
        {
          imWhitePlayer = !imWhitePlayer;                                  //Switch the value of the color player and then putting it back, to simulate his moves
          allSimulatedDest.addAll(computeDestinations(j, k, true));        //Compute destinations for each piece
          imWhitePlayer = !imWhitePlayer;
        }
        else if(grid[k][j] >= 1 && grid[k][j] <= 6 && !imWhitePlayer)
        {
          imWhitePlayer = !imWhitePlayer;
          allSimulatedDest.addAll(computeDestinations(j, k, true));
          imWhitePlayer = !imWhitePlayer;
        }
      }
    }
    PVector myKing = findKingPlace();                                //Find the placement of the king, after the movement simulation
    
    boolean willBeCheck = false;
    for(int j=0; j<allSimulatedDest.size(); j++)                //If one of the destination of one of the piece of the next player fall right in the player king, then the movement is impossible
    {
      if(allSimulatedDest.get(j).x == myKing.x && allSimulatedDest.get(j).y == myKing.y)
      {
        willBeCheck = true;
        break;
      }
    }
    if(!willBeCheck) boolGrid[boolY][boolX] = true;            //If for this destination there is no danger for the king, put the value to true in the bool grid
    for(int j=0; j<rows; j++)
    {
      arrayCopy(tempGrid[j], grid[j]);                         //And get back the values of the untouched grid thanks to the temporary grid
    }
  }
}

PVector findKingPlace(){
 PVector myKing = new PVector();
 for(int j=0; j<rows; j++)
  {
    for(int k=0; k<rows; k++)
    {
      if(imWhitePlayer && grid[k][j] == 6)
      {
        myKing.x = k;
        myKing.y = j;
        break;
      }
      else if(!imWhitePlayer && grid[k][j] == 16)
      {
        myKing.x = k;
        myKing.y = j;
        break;
      }
    }
  }
 return myKing;
}

void resetBoolGrid()
{
  for(int i=0; i<rows; i++)
    for(int j=0; j<rows; j++)
      boolGrid[i][j] = false;
}



ArrayList<PVector> calcPawnMovement(int x, int y, boolean danger)
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  if(!imWhitePlayer)
  {
    if(y-1 >= 0 && grid[y-1][x] == 0 && !danger)
    {
      PVector vec = new PVector(y-1, x);
      destinations.add(vec);
      if(y==6 && y-2 >= 0 && grid[y-2][x] == 0)
      {
        PVector vec2 = new PVector(y-2, x);
        destinations.add(vec2);
      }
    }
    if(y-1 >= 0 && x-1 >= 0 && (isThisCaseColor(x-1, y-1, true)))
    {
      PVector vec = new PVector(y-1, x-1);
      destinations.add(vec);
    }
    if(y-1 >= 0 && x+1 < rows && (isThisCaseColor(x+1, y-1, true)))
    {
      PVector vec = new PVector(y-1, x+1);
      destinations.add(vec);
    }
  }
  else if(imWhitePlayer)
  {
    if(y+1 < rows && grid[y+1][x] == 0 && !danger)
    {
      PVector vec = new PVector(y+1, x);
      destinations.add(vec);
      if(y==1 && y+2 < rows && grid[y+2][x] == 0)
      {
        PVector vec2 = new PVector(y+2, x);
        destinations.add(vec2);
      }
    }
    if(y+1 < rows && x-1 >= 0 && (isThisCaseColor(x-1, y+1, false)))
    {
      PVector vec = new PVector(y+1, x-1);
      destinations.add(vec);
    }
    if(y+1 < rows && x+1 < rows && (isThisCaseColor(x+1, y+1, false)))
    {
      PVector vec = new PVector(y+1, x+1);
      destinations.add(vec);
    }
  }
  return destinations;
}

ArrayList calcTowerMovement(int x, int y)
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  int i = 1;
  while(y+i < rows)
  {
    if(grid[y+i][x] == 0)
    {
      PVector vec = new PVector(y+i, x);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x, y+i, !imWhitePlayer))
      {
        PVector vec = new PVector(y+i, x);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(y-i >= 0)
  {
    if(grid[y-i][x] == 0)
    {
      PVector vec = new PVector(y-i, x);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x, y-i, !imWhitePlayer))
      {
        PVector vec = new PVector(y-i, x);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(x+i < rows)
  {
    if(grid[y][x+i] == 0)
    {
      PVector vec = new PVector(y, x+i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x+i, y, !imWhitePlayer))
      {
        PVector vec = new PVector(y, x+i);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(x-i >= 0)
  {
    if(grid[y][x-i] == 0)
    {
      PVector vec = new PVector(y, x-i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x-i, y, !imWhitePlayer))
      {
        PVector vec = new PVector(y, x-i);
        destinations.add(vec);
      }
      break;
    }
  }
  return destinations;
}

ArrayList<PVector> calcFoolMovement(int x, int y)
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  int i = 1;
  while(y+i < rows && x+i < rows)
  {
    if(grid[y+i][x+i] == 0)
    {
      PVector vec = new PVector(y+i, x+i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x+i, y+i, !imWhitePlayer))
      {
        PVector vec = new PVector(y+i, x+i);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(y+i < rows && x-i >= 0)
  {
    if(grid[y+i][x-i] == 0)
    {
      PVector vec = new PVector(y+i, x-i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x-i, y+i, !imWhitePlayer))
      {
        PVector vec = new PVector(y+i, x-i);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(y-i >= 0 && x-i >= 0)
  {
    if(grid[y-i][x-i] == 0)
    {
      PVector vec = new PVector(y-i, x-i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x-i, y-i, !imWhitePlayer))
      {
        PVector vec = new PVector(y-i, x-i);
        destinations.add(vec);
      }
      break;
    }
  }
  i=1;
  while(y-i >= 0 && x+i < rows)
  {
    if(grid[y-i][x+i] == 0)
    {
      PVector vec = new PVector(y-i, x+i);
      destinations.add(vec);
      i++;
    }
    else
    {
      if(isThisCaseColor(x+i, y-i, !imWhitePlayer))
      {
        PVector vec = new PVector(y-i, x+i);
        destinations.add(vec);
      }
      break;
    }
  }
  return destinations;
}

ArrayList<PVector> calcHorseMovement(int x, int y)
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  if(x-1 >= 0)
  {
    if(y-2 >= 0 && isDestinationPossible(x-1, y-2))
    {
      PVector vec = new PVector(y-2, x-1);
      destinations.add(vec);
    }
    if(y+2 < rows && isDestinationPossible(x-1, y+2))
    {
      PVector vec = new PVector(y+2, x-1);
      destinations.add(vec);
    }
    if(x-2 >= 0)
    {
      if(y-1 >= 0 && isDestinationPossible(x-2, y-1))
      {
        PVector vec = new PVector(y-1, x-2);
        destinations.add(vec);
      }
      if(y+1 < rows && isDestinationPossible(x-2, y+1))
      {
        PVector vec = new PVector(y+1, x-2);
        destinations.add(vec);
      }
    }
  }
  if(x+1 < rows)
  {
    if(y-2 >= 0 && isDestinationPossible(x+1, y-2))
    {
      PVector vec = new PVector(y-2, x+1);
      destinations.add(vec);
    }
    if(y+2 < rows && isDestinationPossible(x+1, y+2))
    {
      PVector vec = new PVector(y+2, x+1);
      destinations.add(vec);
    }
    if(x+2 < rows)
    {
      if(y-1 >= 0 && isDestinationPossible(x+2, y-1))
      {
        PVector vec = new PVector(y-1, x+2);
        destinations.add(vec);
      }
      if(y+1 < rows && isDestinationPossible(x+2, y+1))
      {
        PVector vec = new PVector(y+1, x+2);
        destinations.add(vec);
      }
    }
  }
  return destinations;
}

ArrayList<PVector> calcKingMovement(int x, int y)
{
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  if(x-1 >= 0)
  {
    if(y-1 >= 0 && isDestinationPossible(x-1, y-1))
    {
      PVector vec = new PVector(y-1, x-1);
      destinations.add(vec);
    }
    if(y+1 < rows && isDestinationPossible(x-1, y+1))
    {
      PVector vec = new PVector(y+1, x-1);
      destinations.add(vec);
    }
    if(isDestinationPossible(x-1, y))
    {
      PVector vec = new PVector(y, x-1);
      destinations.add(vec);
    }
  }
  if(x+1 < rows)
  {
    if(y-1 >= 0 && isDestinationPossible(x+1, y-1))
    {
      PVector vec = new PVector(y-1, x+1);
      destinations.add(vec);
    }
    if(y+1 < rows && isDestinationPossible(x+1, y+1))
    {
      PVector vec = new PVector(y+1, x+1);
      destinations.add(vec);
    }
    if(isDestinationPossible(x+1, y))
    {
      PVector vec = new PVector(y, x+1);
      destinations.add(vec);
    }
  }
  if(y-1 >= 0 && isDestinationPossible(x, y-1))
  {
    PVector vec = new PVector(y-1, x);
    destinations.add(vec);
  }
  if(y+1 < rows && isDestinationPossible(x, y+1))
  {
    PVector vec = new PVector(y+1, x);
    destinations.add(vec);
  }
  return destinations;
}



boolean isDestinationPossible(int x, int y)
{
  if(grid[y][x] == 0 || isThisCaseColor(x, y, !imWhitePlayer)) return true;
  else return false;
}

boolean isThisCaseColor(int x, int y, boolean white)           //Return if the given case contains a piece of the asked color
{
  if(grid[y][x] == 0) return false;
  if(white)
  {
    if(grid[y][x] >= 1 && grid[y][x] <= 6) return true;
    else return false;
  }
  else
  {
    if(grid[y][x] >= 11 && grid[y][x] <= 16) return true;
    else return false;
  }
}

int calculateMouseCase(boolean isX)     //Return the index of the actual mouse position on the board
{
  float pointer = 0;                    //Pointer to compare to mouse coordinates
  int index = -1;                       //index for the hovered case
  float mouseValue;
  if(isX) mouseValue = mouseX;
  else mouseValue = mouseY;
  while(pointer < mouseValue)
  {
    pointer += caseSpace;
    index++;
  }
  if(index < 0) return 0;
  else return index;
}

color chooseCaseColor(int x, int y)                      //Return the color of each case of the board 
{
  color col;
  if(caseHovered.x == x && caseHovered.y == y)           //Default colors in Hover
  {
    if(isDarkCase) col = darkHover;
    else col = lightHover;
  }
  else                                                   //Default colors
  {
    if(isDarkCase) col = darkCase;
    else col = lightCase;
  }
  if(selectedCaseX == x && selectedCaseY == y)           //Actual Selected case
  {
    col = greenSelected;
  }
  if(boolGrid[y][x] == true)                             //Possible movement of selected Case
  {
    if(isDarkCase) col = darkMove;
    else col = lightMove;
    if(caseHovered.x == x && caseHovered.y == y)
    {
      col = hoverMove;                                   //Hover of possible movement
    }
  }
  return col;
}













//Void = 0;
//Pawn = 1;
//Tower = 2;
//Horse = 3;
//Fool = 4;
//Queen = 5;
//King = 6;
//Black = +10;
